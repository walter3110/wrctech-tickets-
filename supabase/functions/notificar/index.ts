// WRCtech Tickets - función "notificar"
// La llama un Database Webhook de Supabase cada vez que se crea o cambia un ticket,
// y manda la notificación push a los celulares que corresponden (vía Firebase).
//
// Secretos necesarios (Edge Functions > Secrets):
//   FIREBASE_SERVICE_ACCOUNT  -> el JSON completo de la cuenta de servicio de Firebase
//   WEBHOOK_SECRET            -> la misma clave que se pone en el header del webhook

import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

const claveAdmin =
  (() => {
    try {
      return JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}")["default"];
    } catch {
      return undefined;
    }
  })() ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, claveAdmin!);
const cuenta = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}");
const SECRETO = Deno.env.get("WEBHOOK_SECRET");

type Ticket = {
  id: string;
  numero: number;
  origen: "empleado" | "sistemas";
  empleado: string;
  equipo: string;
  descripcion: string;
  urgencia: "normal" | "urgente";
  estado: string;
  nota_resolucion: string | null;
  presupuesto_detalle: string | null;
  presupuesto_monto: number | null;
};

// ---------- Acceso a Firebase (token OAuth de la cuenta de servicio) ----------

let tokenGuardado: { valor: string; vence: number } | null = null;

async function tokenGoogle(): Promise<string> {
  const ahora = Math.floor(Date.now() / 1000);
  if (tokenGuardado && tokenGuardado.vence > ahora + 60) return tokenGuardado.valor;

  const clave = await importPKCS8(cuenta.private_key, "RS256");
  const jwt = await new SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(cuenta.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(ahora)
    .setExpirationTime(ahora + 3600)
    .sign(clave);

  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const datos = await r.json();
  if (!r.ok) throw new Error("Firebase rechazó la cuenta de servicio: " + JSON.stringify(datos));

  tokenGuardado = { valor: datos.access_token, vence: ahora + datos.expires_in };
  return datos.access_token;
}

// ---------- A quién avisar ----------

async function tokensDe(roles: string[]): Promise<string[]> {
  const { data: perfiles } = await supabase.from("perfiles").select("id").in("rol", roles);
  const ids = (perfiles ?? []).map((p) => p.id);
  if (ids.length === 0) return [];
  const { data: disp } = await supabase.from("dispositivos").select("token").in("usuario_id", ids);
  return (disp ?? []).map((d) => d.token);
}

async function avisar(roles: string[], titulo: string, cuerpo: string, ticketId: string) {
  const tokens = await tokensDe(roles);
  if (tokens.length === 0) return 0;
  const acceso = await tokenGoogle();
  let enviados = 0;

  await Promise.all(tokens.map(async (token) => {
    const r = await fetch(
      `https://fcm.googleapis.com/v1/projects/${cuenta.project_id}/messages:send`,
      {
        method: "POST",
        headers: { Authorization: `Bearer ${acceso}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: titulo, body: cuerpo },
            data: { ticket_id: ticketId },
            android: { priority: "high", notification: { sound: "default" } },
          },
        }),
      },
    );
    if (r.ok) {
      enviados++;
      return;
    }
    const error = await r.text();
    // Celular que desinstaló la app o cambió de token: se borra.
    if (r.status === 404 || error.includes("UNREGISTERED")) {
      await supabase.from("dispositivos").delete().eq("token", token);
    } else {
      console.error("FCM", r.status, error);
    }
  }));
  return enviados;
}

// ---------- Textos ----------

const num = (n: number) => "#" + String(n).padStart(4, "0");
const plata = (m: number | null) =>
  m == null ? "" : " ($ " + Math.round(m).toLocaleString("es-AR") + ")";

async function procesar(tipo: string, t: Ticket, antes: Ticket | null): Promise<number> {
  // Ticket nuevo pedido por un empleado -> avisar a Sistemas
  if (tipo === "INSERT") {
    if (t.origen !== "empleado") return 0;
    const urgente = t.urgencia === "urgente" ? "URGENTE · " : "";
    return avisar(
      ["tecnico"],
      `${urgente}Ticket ${num(t.numero)} · ${t.equipo}`,
      `${t.descripcion} (${t.empleado})`,
      t.id,
    );
  }

  if (tipo !== "UPDATE" || !antes || antes.estado === t.estado) return 0;

  switch (t.estado) {
    case "a_presupuestar":
      return avisar(
        ["farmaceutico"],
        `Presupuesto para aprobar · ${num(t.numero)}`,
        `${t.equipo}: ${t.presupuesto_detalle ?? ""}${plata(t.presupuesto_monto)}`,
        t.id,
      );
    case "presupuesto_aprobado":
      return avisar(["tecnico"], `Presupuesto aprobado · ${num(t.numero)}`, t.equipo, t.id);
    case "presupuesto_rechazado":
      return avisar(["tecnico"], `Presupuesto rechazado · ${num(t.numero)}`, t.equipo, t.id);
    case "resuelto": {
      // El farmacéutico se entera de todo; la farmacia solo de lo que pidió.
      const roles = t.origen === "empleado" ? ["farmaceutico", "farmacia"] : ["farmaceutico"];
      return avisar(
        roles,
        `Ticket ${num(t.numero)} resuelto · ${t.equipo}`,
        t.nota_resolucion ?? "",
        t.id,
      );
    }
    default:
      return 0;
  }
}

Deno.serve(async (req) => {
  if (!SECRETO || req.headers.get("x-webhook-secret") !== SECRETO) {
    return new Response("No autorizado", { status: 401 });
  }
  try {
    const { type, record, old_record } = await req.json();
    const enviados = await procesar(type, record as Ticket, old_record as Ticket | null);
    return Response.json({ ok: true, enviados });
  } catch (e) {
    console.error(e);
    return Response.json({ ok: false, error: String(e) }, { status: 500 });
  }
});
