import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pantallas/inicio.dart';
import 'pantallas/login.dart';
import 'supa.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseKey,
  );
  runApp(const SoporteApp());
}

class SoporteApp extends StatelessWidget {
  const SoporteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WRCtech Soporte',
      debugShowCheckedModeBanner: false,
      theme: wrctechTema(),
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Raiz(),
    );
  }
}

/// Muestra el login la primera vez; después queda siempre en la pantalla principal.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) {
        final sesion = supabase.auth.currentSession;
        return sesion == null ? const LoginPage() : const InicioPage();
      },
    );
  }
}
