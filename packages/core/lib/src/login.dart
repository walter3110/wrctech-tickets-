import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


/// Pantalla de ingreso. El usuario (email) es fijo por app; solo se pide la contraseña.
class LoginPage extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final String email;
  final String etiquetaClave;
  final String textoBoton;
  final IconData icono;
  const LoginPage({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.email,
    this.etiquetaClave = 'Contraseña',
    this.textoBoton = 'Ingresar',
    this.icono = Icons.lock_outline,
  });

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
      await Supabase.instance.client.auth.signInWithPassword(
        email: widget.email,
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
                Icon(widget.icono, size: 72, color: tema.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  widget.titulo,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitulo,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _clave,
                  obscureText: !_verClave,
                  onSubmitted: (_) => _entrar(),
                  decoration: InputDecoration(
                    labelText: widget.etiquetaClave,
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
                      : Text(widget.textoBoton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
