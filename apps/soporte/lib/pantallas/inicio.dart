import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../supa.dart';
import 'nuevo_ticket.dart';

/// Pantalla principal: botón para pedir ayuda y lista de pedidos con su estado.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  // Se actualiza sola cuando Sistemas cambia el estado de un ticket.
  late final Stream<List<Map<String, dynamic>>> _tickets = supabase
      .from('tickets')
      .stream(primaryKey: ['id'])
      .order('numero', ascending: false)
      .limit(50);

  Future<void> _cerrarSesion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Desactivar este celular?'),
        content: const Text(
            'Para volver a usar la app va a hacer falta la contraseña de Sistemas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Desactivar')),
        ],
      ),
    );
    if (ok == true) await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WRCtech Soporte'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) => _cerrarSesion(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'salir', child: Text('Desactivar celular')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NuevoTicketPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Crear ticket'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _tickets,
        builder: (context, snap) {
          if (snap.hasError) {
            return const _Mensaje(
              icono: Icons.wifi_off,
              texto: 'Sin conexión. Revisá el WiFi o los datos.',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snap.data!.map(Ticket.desdeMapa).toList();
          if (tickets.isEmpty) {
            return const _Mensaje(
              icono: Icons.check_circle_outline,
              texto: 'Todavía no hay tickets.\nSi algo no funciona, tocá "Crear ticket".',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _TarjetaTicket(tickets[i]),
          );
        },
      ),
    );
  }
}

class _TarjetaTicket extends StatelessWidget {
  final Ticket t;
  const _TarjetaTicket(this.t);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verDetalle(context),
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
                    const SizedBox(width: 8),
                    const Icon(Icons.priority_high, color: Colors.red, size: 18),
                  ],
                  const Spacer(),
                  ChipEstado(t.estado),
                ],
              ),
              const SizedBox(height: 6),
              Text(t.equipo, style: tema.textTheme.titleSmall),
              Text(t.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text('${t.empleado} · ${fechaCorta(t.creadoEn)}',
                  style: tema.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  void _verDetalle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Ticket ${t.numeroTexto}', style: Theme.of(c).textTheme.titleLarge),
              const Spacer(),
              ChipEstado(t.estado),
            ]),
            const SizedBox(height: 16),
            _Dato('Equipo', t.equipo),
            _Dato('Problema', t.descripcion),
            _Dato('Pedido por', '${t.empleado} · ${fechaCorta(t.creadoEn)}'),
            if (t.resueltoEn != null) _Dato('Resuelto', fechaCorta(t.resueltoEn!)),
            if (t.notaResolucion != null && t.notaResolucion!.isNotEmpty)
              _Dato('Qué se hizo', t.notaResolucion!),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String titulo;
  final String valor;
  const _Dato(this.titulo, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.labelMedium),
          Text(valor, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Mensaje({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
