import 'package:flutter/material.dart';

import 'formato.dart';
import 'ticket.dart';

/// Tarjeta de un ticket en una lista.
class TarjetaTicket extends StatelessWidget {
  final Ticket t;
  final VoidCallback onTap;
  const TarjetaTicket(this.t, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: t.esUrgente && t.estaAbierto
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 1.5),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(t.numeroTexto,
                      style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (t.esUrgente) ...[
                    const SizedBox(width: 6),
                    const Text('URGENTE',
                        style: TextStyle(
                            color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                  if (t.esDeSistemas) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.engineering, size: 18, color: tema.colorScheme.outline),
                  ],
                  const Spacer(),
                  ChipEstado(t.estado),
                ],
              ),
              const SizedBox(height: 6),
              Text(t.equipo, style: tema.textTheme.titleSmall),
              Text(t.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(
                '${t.esDeSistemas ? 'Iniciado por Sistemas' : t.empleado} · ${fechaCorta(t.creadoEn)}',
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado para listas vacías o sin conexión.
class AvisoVacio extends StatelessWidget {
  final IconData icono;
  final String texto;
  const AvisoVacio(this.icono, this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
