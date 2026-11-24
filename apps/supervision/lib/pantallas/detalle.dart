import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../supa.dart';

/// Detalle de un ticket. El farmacéutico solo puede aprobar o rechazar presupuestos.
class DetallePage extends StatefulWidget {
  final String ticketId;
  const DetallePage(this.ticketId, {super.key});

  @override
  State<DetallePage> createState() => _DetallePageState();
}

class _DetallePageState extends State<DetallePage> {
  Stream<List<Map<String, dynamic>>> _ticket() =>
      supabase.from('tickets').stream(primaryKey: ['id']).eq('id', widget.ticketId);
  bool _guardando = false;

  Future<void> _decidir(Ticket t, bool aprobar) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(aprobar ? '¿Aprobar el presupuesto?' : '¿Rechazar el presupuesto?'),
        content: Text(
          '${t.presupuestoDetalle ?? ''}'
          '${t.presupuestoMonto != null ? '\n\n${plata(t.presupuestoMonto!)}' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: aprobar ? null : FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(aprobar ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _guardando = true);
    try {
      await supabase
          .from('tickets')
          .update({'estado': aprobar ? 'presupuesto_aprobado' : 'presupuesto_rechazado'})
          .eq('id', widget.ticketId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(aprobar
              ? 'Presupuesto aprobado. Sistemas ya fue avisado.'
              : 'Presupuesto rechazado. Sistemas ya fue avisado.'),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo guardar. Revisá la conexión.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EnVivo(
      crear: _ticket,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: snap.hasError
                  ? const Text('Reconectando…')
                  : const CircularProgressIndicator(),
            ),
          );
        }
        final t = Ticket.desdeMapa(snap.data!.first);
        final tema = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: Text('Ticket ${t.numeroTexto}')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(children: [
                ChipEstado(t.estado),
                if (t.esUrgente) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Urgente'),
                    avatar: Icon(Icons.priority_high, color: Colors.red, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ]),
              const SizedBox(height: 16),
              Text(t.equipo, style: tema.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(t.descripcion, style: tema.textTheme.bodyLarge),
              const Divider(height: 32),
              _Dato(Icons.person_outline, 'Pedido por',
                  t.esDeSistemas ? 'Sistemas (trabajo sin pedido)' : t.empleado),
              _Dato(Icons.schedule, 'Creado', fechaCorta(t.creadoEn)),
              if (t.tomadoEn != null) _Dato(Icons.play_arrow, 'Tomado', fechaCorta(t.tomadoEn!)),
              if (t.resueltoEn != null)
                _Dato(Icons.check_circle_outline, 'Resuelto', fechaCorta(t.resueltoEn!)),
              if (t.notaResolucion?.isNotEmpty ?? false)
                _Dato(Icons.notes, 'Qué se hizo', t.notaResolucion!),
              if (t.materiales?.isNotEmpty ?? false)
                _Dato(Icons.inventory_2_outlined, 'Materiales', t.materiales!),
              if (t.presupuestoDetalle?.isNotEmpty ?? false)
                _Dato(
                  Icons.request_quote_outlined,
                  'Presupuesto',
                  '${t.presupuestoDetalle!}'
                      '${t.presupuestoMonto != null ? '\n${plata(t.presupuestoMonto!)}' : ''}',
                ),
              if (t.estado == 'a_presupuestar') ...[
                const SizedBox(height: 16),
                if (_guardando)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  FilledButton.icon(
                    onPressed: () => _decidir(t, true),
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: const Text('Aprobar presupuesto'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _decidir(t, false),
                    icon: const Icon(Icons.thumb_down_outlined, color: Colors.red),
                    label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  const _Dato(this.icono, this.titulo, this.valor);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: tema.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: tema.textTheme.labelMedium),
                Text(valor, style: tema.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
