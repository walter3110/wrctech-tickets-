import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../supa.dart';

class DetallePage extends StatefulWidget {
  final String ticketId;
  const DetallePage(this.ticketId, {super.key});

  @override
  State<DetallePage> createState() => _DetallePageState();
}

class _DetallePageState extends State<DetallePage> {
  late final Stream<List<Map<String, dynamic>>> _ticket =
      supabase.from('tickets').stream(primaryKey: ['id']).eq('id', widget.ticketId);
  bool _guardando = false;

  Future<void> _guardar(Map<String, dynamic> cambios, String aviso) async {
    setState(() => _guardando = true);
    try {
      await supabase.from('tickets').update(cambios).eq('id', widget.ticketId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));
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

  Future<void> _resolver(Ticket t) async {
    final res = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _DialogoResolver(materialesPrevios: t.materiales),
    );
    if (res == null) return;
    await _guardar({
      'estado': 'resuelto',
      'nota_resolucion': res.$1,
      'materiales': res.$2.isEmpty ? null : res.$2,
    }, 'Ticket ${t.numeroTexto} resuelto');
  }

  Future<void> _presupuestar(Ticket t) async {
    final res = await showDialog<(String, double)>(
      context: context,
      builder: (_) => const _DialogoPresupuesto(),
    );
    if (res == null) return;
    await _guardar({
      'estado': 'a_presupuestar',
      'presupuesto_detalle': res.$1,
      'presupuesto_monto': res.$2,
    }, 'Presupuesto enviado al farmacéutico');
  }

  List<Widget> _acciones(Ticket t) {
    final enProceso = FilledButton.tonalIcon(
      onPressed: () => _guardar({'estado': 'en_proceso'}, 'Ticket ${t.numeroTexto} en proceso'),
      icon: const Icon(Icons.play_arrow),
      label: const Text('Tomar: en proceso'),
    );
    final resuelto = FilledButton.icon(
      onPressed: () => _resolver(t),
      icon: const Icon(Icons.check),
      label: const Text('Marcar resuelto'),
    );
    final presupuestar = OutlinedButton.icon(
      onPressed: () => _presupuestar(t),
      icon: const Icon(Icons.request_quote_outlined),
      label: const Text('Mandar a presupuestar'),
    );

    switch (t.estado) {
      case 'nuevo':
        return [enProceso, resuelto, presupuestar];
      case 'en_proceso':
        return [resuelto, presupuestar];
      case 'a_presupuestar':
        return [
          const _Nota(Icons.hourglass_top, 'Esperando que el farmacéutico apruebe el presupuesto.'),
          OutlinedButton.icon(
            onPressed: () =>
                _guardar({'estado': 'en_proceso'}, 'Presupuesto cancelado, vuelve a en proceso'),
            icon: const Icon(Icons.undo),
            label: const Text('Cancelar presupuesto'),
          ),
        ];
      case 'presupuesto_aprobado':
        return [
          const _Nota(Icons.thumb_up_outlined, 'Presupuesto aprobado. Ya podés hacer el trabajo.'),
          resuelto,
        ];
      case 'presupuesto_rechazado':
        return [
          const _Nota(Icons.thumb_down_outlined, 'El farmacéutico rechazó el presupuesto.'),
          OutlinedButton.icon(
            onPressed: () => _guardar({'estado': 'cerrado'}, 'Ticket cerrado'),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Cerrar ticket'),
          ),
          OutlinedButton.icon(
            onPressed: () => _guardar({'estado': 'en_proceso'}, 'Ticket reabierto'),
            icon: const Icon(Icons.replay),
            label: const Text('Buscar otra solución'),
          ),
        ];
      default: // resuelto o cerrado
        return [
          OutlinedButton.icon(
            onPressed: () => _guardar({'estado': 'en_proceso'}, 'Ticket reabierto'),
            icon: const Icon(Icons.replay),
            label: const Text('Reabrir'),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _ticket,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: snap.hasError
                  ? const Text('Sin conexión.')
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
              _Dato(Icons.person_outline, 'Creado por',
                  t.esDeSistemas ? 'Sistemas (sin pedido)' : t.empleado),
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
              const SizedBox(height: 16),
              if (_guardando)
                const Center(child: CircularProgressIndicator())
              else
                ..._acciones(t).map(
                  (w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w),
                ),
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

class _Nota extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Nota(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icono, color: c.onSecondaryContainer),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: TextStyle(color: c.onSecondaryContainer))),
      ]),
    );
  }
}

/// Pide qué se hizo y qué materiales se usaron.
class _DialogoResolver extends StatefulWidget {
  final String? materialesPrevios;
  const _DialogoResolver({this.materialesPrevios});

  @override
  State<_DialogoResolver> createState() => _DialogoResolverState();
}

class _DialogoResolverState extends State<_DialogoResolver> {
  final _nota = TextEditingController();
  late final _materiales = TextEditingController(text: widget.materialesPrevios ?? '');
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marcar resuelto'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _nota,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: '¿Qué hiciste?',
              hintText: 'Ej: cambio de fuente',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _materiales,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Materiales usados (opcional)',
              hintText: 'Ej: 1 fuente 500W',
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            if (_nota.text.trim().isEmpty) {
              setState(() => _error = 'Contá brevemente qué hiciste');
              return;
            }
            Navigator.pop(context, (_nota.text.trim(), _materiales.text.trim()));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Pide el detalle y el monto del presupuesto.
class _DialogoPresupuesto extends StatefulWidget {
  const _DialogoPresupuesto();

  @override
  State<_DialogoPresupuesto> createState() => _DialogoPresupuestoState();
}

class _DialogoPresupuestoState extends State<_DialogoPresupuesto> {
  final _detalle = TextEditingController();
  final _monto = TextEditingController();
  String? _errorDetalle;
  String? _errorMonto;

  double? _leerMonto() {
    // Acepta "45000", "45.000" o "45.000,50".
    final limpio = _monto.text.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpio);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mandar a presupuestar'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _detalle,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: '¿Qué hay que comprar o hacer?',
              hintText: 'Ej: fuente nueva para Terminal 3',
              errorText: _errorDetalle,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto estimado',
              prefixText: '\$ ',
              errorText: _errorMonto,
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            final monto = _leerMonto();
            setState(() {
              _errorDetalle = _detalle.text.trim().isEmpty ? 'Completá el detalle' : null;
              _errorMonto = monto == null ? 'Poné un monto (solo números)' : null;
            });
            if (_errorDetalle != null || _errorMonto != null) return;
            Navigator.pop(context, (_detalle.text.trim(), monto!));
          },
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
