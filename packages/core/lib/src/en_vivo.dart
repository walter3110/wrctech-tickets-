import 'dart:async';

import 'package:flutter/widgets.dart';

typedef Filas = List<Map<String, dynamic>>;

/// Lista "en vivo" de Supabase que se reconecta sola.
///
/// Android corta la conexión en tiempo real cuando la app queda en segundo plano.
/// Este widget vuelve a conectarse al volver a la app y, si hay un error,
/// reintenta cada pocos segundos mostrando mientras tanto los últimos datos.
class EnVivo extends StatefulWidget {
  final Stream<Filas> Function() crear;
  final Widget Function(BuildContext context, AsyncSnapshot<Filas> snap) builder;

  const EnVivo({super.key, required this.crear, required this.builder});

  @override
  State<EnVivo> createState() => _EnVivoState();
}

class _EnVivoState extends State<EnVivo> with WidgetsBindingObserver {
  late Stream<Filas> _stream = widget.crear();
  Filas? _ultimo;
  Timer? _reintento;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _reconectar();
  }

  void _reconectar() {
    _reintento?.cancel();
    _reintento = null;
    if (mounted) setState(() => _stream = widget.crear());
  }

  @override
  void dispose() {
    _reintento?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Filas>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasData) _ultimo = snap.data;
        if (snap.hasError) {
          _reintento ??= Timer(const Duration(seconds: 3), _reconectar);
          // Mientras reconecta, se siguen mostrando los últimos datos.
          if (_ultimo != null) {
            return widget.builder(
                context, AsyncSnapshot.withData(ConnectionState.active, _ultimo!));
          }
        }
        return widget.builder(context, snap);
      },
    );
  }
}
