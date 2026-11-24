import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Para mostrar avisos (SnackBar) desde cualquier lugar de la app.
final mensajesGlobales = GlobalKey<ScaffoldMessengerState>();

bool _escuchando = false;

/// Pide permiso de notificaciones y registra este celular en la tabla
/// `dispositivos`, para que la función `notificar` de Supabase le mande avisos.
/// Llamar después de iniciar sesión. Si algo falla, la app sigue funcionando.
Future<void> activarNotificaciones(FirebaseOptions opciones) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: opciones);
    }
    final fm = FirebaseMessaging.instance;
    await fm.requestPermission();

    Future<void> guardar(String? token) async {
      final cliente = Supabase.instance.client;
      final uid = cliente.auth.currentUser?.id;
      if (token == null || uid == null) return;
      await cliente.from('dispositivos').upsert({
        'token': token,
        'usuario_id': uid,
        'actualizado_en': DateTime.now().toUtc().toIso8601String(),
      });
    }

    await guardar(await fm.getToken());

    if (!_escuchando) {
      _escuchando = true;
      fm.onTokenRefresh.listen(guardar);
      // Con la app abierta Android no muestra la notificación: la mostramos acá.
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n == null) return;
        mensajesGlobales.currentState?.showSnackBar(SnackBar(
          content: Text([n.title, n.body].whereType<String>().join('\n')),
          duration: const Duration(seconds: 6),
        ));
      });
    }
  } catch (e) {
    debugPrint('No se pudieron activar las notificaciones: $e');
  }
}
