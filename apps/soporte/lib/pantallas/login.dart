import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supa.dart';

/// Configuración inicial del celular de la farmacia. La hace Sistemas una sola vez.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _verClave = false;
  String? _error;

  Future<void> _entrar() async {
    if (_clave.text.trim().isEmpty) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await supabase.auth.signInWithPassword(
        email: AppConfig.emailFarmacia,
        password: _clave.text.trim(),
      );
    } on AuthException {
      _error = 'Contraseña incorrecta.';
    } catch (_) {
      _error = 'No hay conexión a internet. Probá de nuevo.';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.support_agent, size: 72, color: tema.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'WRCtech Soporte',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configuración inicial del celular de la farmacia.\nSolo la realiza Sistemas.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _clave,
                  obscureText: !_verClave,
                  onSubmitted: (_) => _entrar(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña de la farmacia',
                    errorText: _error,
                    suffixIcon: IconButton(
                      icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _verClave = !_verClave),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _cargando ? null : _entrar,
                  child: _cargando
                      ? const SizedBox(
                          width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Activar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
