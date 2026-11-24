import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../firebase_opciones.dart';
import '../supa.dart';
import 'detalle.dart';

/// Panel del farmacéutico: presupuestos para aprobar, tickets abiertos y terminados.
class PanelPage extends StatefulWidget {
  const PanelPage({super.key});

  @override
  State<PanelPage> createState() => _PanelPageState();
}

class _PanelPageState extends State<PanelPage> {
  late final Stream<List<Map<String, dynamic>>> _tickets = supabase
      .from('tickets')
      .stream(primaryKey: ['id'])
      .order('numero', ascending: false)
      .limit(300);

  @override
  void initState() {
    super.initState();
    activarNotificaciones(firebaseOpciones);
  }

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
        final paraAprobar = todos.where((t) => t.estado == 'a_presupuestar').toList();
        final abiertos =
            todos.where((t) => t.estaAbierto && t.estado != 'a_presupuestar').toList();
        final terminados = todos.where((t) => !t.estaAbierto).toList();

        Widget lista(List<Ticket> tickets, String vacio) {
          if (snap.hasError) {
            return const AvisoVacio(Icons.wifi_off, 'Sin conexión. Reintentando…');
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (tickets.isEmpty) return AvisoVacio(Icons.inbox_outlined, vacio);
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => TarjetaTicket(
              tickets[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetallePage(tickets[i].id)),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('WRCtech Supervisión'),
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
                  Tab(text: 'Aprobar (${paraAprobar.length})'),
                  Tab(text: 'Abiertos (${abiertos.length})'),
                  const Tab(text: 'Terminados'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                lista(paraAprobar, 'No hay presupuestos para aprobar.'),
                lista(abiertos, 'No hay tickets abiertos.'),
                lista(terminados, 'Todavía no hay tickets terminados.'),
              ],
            ),
          ),
        );
      },
    );
  }
}
