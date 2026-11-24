import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pantallas/bandeja.dart';
import 'supa.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseKey,
  );
  runApp(const TecnicoApp());
}

class TecnicoApp extends StatelessWidget {
  const TecnicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WRCtech Tickets',
      debugShowCheckedModeBanner: false,
      theme: wrctechTema(),
      scaffoldMessengerKey: mensajesGlobales,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, _) {
          final sesion = supabase.auth.currentSession;
          return sesion == null
              ? const LoginPage(
                  titulo: 'WRCtech Tickets',
                  subtitulo: 'Bandeja de Sistemas',
                  email: AppConfig.emailTecnico,
                  icono: Icons.build_circle_outlined,
                )
              : const BandejaPage();
        },
      ),
    );
  }
}
