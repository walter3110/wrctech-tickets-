import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../supa.dart';
import 'detalle.dart';
import 'nuevo_trabajo.dart';

/// Orden de los pendientes: lo que hay que atender primero, arriba.
const _prioridad = {
  'nuevo': 0,
  'presupuesto_aprobado': 1,
  'en_proceso': 2,
  'a_presupuestar': 3,
};

class BandejaPage extends StatefulWidget {
  const BandejaPage({super.key});

  @override
  State<BandejaPage> createState() => _BandejaPageState();
}

class _BandejaPageState extends State<BandejaPage> {
  late final Stream<List<Map<String, dynamic>>> _tickets = supabase
      .from('tickets')
      .stream(primaryKey: ['id'])
      .order('numero', ascending: false)
      .limit(300);

  Future<void> _salir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok == true) await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _tickets,
      builder: (context, snap) {
        final todos = snap.data?.map(Ticket.desdeMapa).toList() ?? <Ticket>[];

        final pendientes = todos.where((t) => t.estaAbierto).toList()
          ..sort((a, b) {
            final pa = _prioridad[a.estado]! - (a.esUrgente ? 10 : 0);
            final pb = _prioridad[b.estado]! - (b.esUrgente ? 10 : 0);
            if (pa != pb) return pa.compareTo(pb);
            return a.numero.compareTo(b.numero); // el más viejo primero
          });
        final hechos = todos.where((t) => !t.estaAbierto).toList();

        Widget cuerpo(List<Ticket> lista, String vacio) {
          if (snap.hasError) {
            return const _Aviso(Icons.wifi_off, 'Sin conexión. Reintentando…');
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (lista.isEmpty) return _Aviso(Icons.inbox_outlined, vacio);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => TarjetaTicket(
              lista[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetallePage(lista[i].id)),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('WRCtech Tickets'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (_) => _salir(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
                  ],
                ),
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'Pendientes (${pendientes.length})'),
                  const Tab(text: 'Hechos'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NuevoTrabajoPage()),
              ),
              icon: const Icon(Icons.add_task),
              label: const Text('Nuevo trabajo'),
            ),
            body: TabBarView(
              children: [
                cuerpo(pendientes, 'No hay tickets pendientes.'),
                cuerpo(hechos, 'Todavía no hay tickets terminados.'),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Aviso(this.icono, this.texto);

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
