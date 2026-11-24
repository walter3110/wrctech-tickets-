-- =====================================================================
-- WRCtech Tickets - Fase 1: base de datos en Supabase
-- Pegar TODO en Supabase > SQL Editor > New query > Run
-- =====================================================================

-- ---------- Tipos ----------
create type rol_usuario as enum ('farmacia', 'tecnico', 'farmaceutico');

create type estado_ticket as enum (
  'nuevo',
  'en_proceso',
  'a_presupuestar',
  'presupuesto_aprobado',
  'presupuesto_rechazado',
  'resuelto',
  'cerrado'
);

create type origen_ticket as enum ('empleado', 'sistemas');
create type urgencia_ticket as enum ('normal', 'urgente');

-- ---------- Tablas ----------

-- Un perfil por cada usuario (celular farmacia, vos, farmacéutico)
create table perfiles (
  id     uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  rol    rol_usuario not null
);

-- Numeración correlativa de tickets (#1, #2, #3...)
create sequence ticket_numero_seq start 1;

create table tickets (
  id                  uuid primary key default gen_random_uuid(),
  numero              integer not null unique,          -- lo asigna la base, nunca la app
  origen              origen_ticket   not null default 'empleado',
  empleado            text not null,                    -- nombre escrito por el empleado (o vos)
  equipo              text not null,                    -- ej. "Computadora 3", "Impresora"
  descripcion         text not null,
  urgencia            urgencia_ticket not null default 'normal',
  estado              estado_ticket   not null default 'nuevo',
  nota_resolucion     text,                             -- qué se hizo
  materiales          text,                             -- ej. "2 teclados, 1 mouse"
  presupuesto_detalle text,
  presupuesto_monto   numeric(12,2),
  creado_por          uuid references auth.users(id),
  creado_en           timestamptz not null default now(),
  tomado_en           timestamptz,
  resuelto_en         timestamptz,
  actualizado_en      timestamptz not null default now()
);

-- Registro de cada cambio de estado (quién y cuándo)
create table historial_estados (
  id              bigint generated always as identity primary key,
  ticket_id       uuid not null references tickets(id) on delete cascade,
  estado_anterior estado_ticket,
  estado_nuevo    estado_ticket not null,
  cambiado_por    uuid,
  cambiado_en     timestamptz not null default now()
);

-- Tokens de notificación de cada celular (Firebase Cloud Messaging)
create table dispositivos (
  token          text primary key,
  usuario_id     uuid not null references auth.users(id) on delete cascade,
  actualizado_en timestamptz not null default now()
);

-- ---------- Funciones ----------

-- Devuelve el rol del usuario conectado
create or replace function mi_rol()
returns rol_usuario
language sql stable security definer
set search_path = public
as $$
  select rol from perfiles where id = auth.uid()
$$;

-- Valida y completa cada ticket antes de guardarlo
create or replace function validar_ticket()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare
  r            rol_usuario   := mi_rol();
  nuevo_estado estado_ticket := new.estado;
begin
  if r is null then
    raise exception 'Usuario sin perfil asignado';
  end if;

  -- ===== Ticket nuevo =====
  if tg_op = 'INSERT' then
    if r = 'farmacia' then
      -- La farmacia solo puede pedir: todo lo demás lo maneja Sistemas
      new.origen              := 'empleado';
      new.estado              := 'nuevo';
      new.nota_resolucion     := null;
      new.materiales          := null;
      new.presupuesto_detalle := null;
      new.presupuesto_monto   := null;
    elsif r = 'tecnico' then
      -- Trabajos cargados por vos: pueden nacer resueltos
      if new.estado = 'resuelto' then
        new.resuelto_en := now();
      end if;
    else
      raise exception 'Este usuario no puede crear tickets';
    end if;

    new.numero         := nextval('ticket_numero_seq');
    new.creado_por     := auth.uid();
    new.creado_en      := now();
    new.actualizado_en := now();
    return new;
  end if;

  -- ===== Ticket modificado =====
  if r = 'farmaceutico' then
    -- Solo puede aprobar o rechazar un presupuesto, nada más
    if old.estado <> 'a_presupuestar'
       or nuevo_estado not in ('presupuesto_aprobado', 'presupuesto_rechazado') then
      raise exception 'Solo se puede aprobar o rechazar un presupuesto pendiente';
    end if;
    new := old;
    new.estado := nuevo_estado;
  elsif r <> 'tecnico' then
    raise exception 'Este usuario no puede modificar tickets';
  end if;

  if new.estado <> old.estado then
    if new.estado = 'en_proceso' and old.tomado_en is null then
      new.tomado_en := now();
    end if;
    if new.estado = 'resuelto' then
      new.resuelto_en := now();
    end if;
  end if;

  -- Estos datos no se pueden cambiar nunca
  new.numero         := old.numero;
  new.creado_por     := old.creado_por;
  new.creado_en      := old.creado_en;
  new.actualizado_en := now();
  return new;
end;
$$;

create trigger tickets_validar
before insert or update on tickets
for each row execute function validar_ticket();

-- Guarda el historial de estados
create or replace function registrar_estado()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into historial_estados (ticket_id, estado_anterior, estado_nuevo, cambiado_por)
    values (new.id, null, new.estado, auth.uid());
  elsif new.estado <> old.estado then
    insert into historial_estados (ticket_id, estado_anterior, estado_nuevo, cambiado_por)
    values (new.id, old.estado, new.estado, auth.uid());
  end if;
  return null;
end;
$$;

create trigger tickets_historial
after insert or update on tickets
for each row execute function registrar_estado();

-- ---------- Seguridad (quién puede ver y hacer qué) ----------

alter table perfiles enable row level security;
create policy "ver mi perfil" on perfiles
  for select to authenticated
  using (id = auth.uid());

alter table tickets enable row level security;

create policy "ver tickets" on tickets
  for select to authenticated
  using (
    mi_rol() in ('tecnico', 'farmaceutico')
    or (mi_rol() = 'farmacia' and origen = 'empleado')
  );

create policy "crear tickets" on tickets
  for insert to authenticated
  with check (mi_rol() in ('farmacia', 'tecnico'));

create policy "modificar tickets" on tickets
  for update to authenticated
  using (mi_rol() in ('tecnico', 'farmaceutico'))
  with check (mi_rol() in ('tecnico', 'farmaceutico'));

-- Sin política de borrado: nadie puede borrar tickets desde las apps.

alter table historial_estados enable row level security;
create policy "ver historial" on historial_estados
  for select to authenticated
  using (mi_rol() is not null);

alter table dispositivos enable row level security;
create policy "mis dispositivos" on dispositivos
  for all to authenticated
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

-- ---------- Tiempo real (las apps se actualizan solas) ----------
alter publication supabase_realtime add table tickets;
