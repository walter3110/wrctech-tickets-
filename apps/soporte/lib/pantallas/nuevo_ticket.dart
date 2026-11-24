import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../supa.dart';

class NuevoTicketPage extends StatefulWidget {
  const NuevoTicketPage({super.key});

  @override
  State<NuevoTicketPage> createState() => _NuevoTicketPageState();
}

class _NuevoTicketPageState extends State<NuevoTicketPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _equipo = TextEditingController();
  final _descripcion = TextEditingController();
  bool _urgente = false;
  bool _enviando = false;

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final fila = await supabase
          .from('tickets')
          .insert({
            'empleado': _nombre.text.trim(),
            'equipo': _equipo.text.trim(),
            'descripcion': _descripcion.text.trim(),
            'urgencia': _urgente ? 'urgente' : 'normal',
          })
          .select('numero')
          .single();
      final numero = (fila['numero'] as int).toString().padLeft(4, '0');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 56),
          title: const Text('Ticket creado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tu número de ticket es', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                '#$numero',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(c).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Sistemas ya lo tiene en su lista.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ],
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Listo')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo enviar. Revisá la conexión y probá de nuevo.'),
      ));
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _equipo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  String? _obligatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Completá este dato' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo ticket')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Tu nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _obligatorio,
              ),
              const SizedBox(height: 20),
              SelectorEquipo(controller: _equipo),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descripcion,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '¿Qué pasa?',
                  hintText: 'Ej: no enciende, no imprime, está muy lenta…',
                  alignLabelWithHint: true,
                ),
                validator: _obligatorio,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _urgente,
                onChanged: (v) => setState(() => _urgente = v),
                title: const Text('Es urgente'),
                subtitle: const Text('No podemos atender o vender'),
                secondary: Icon(Icons.priority_high,
                    color: _urgente ? Colors.red : Theme.of(context).colorScheme.outline),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _enviando ? null : _enviar,
                icon: _enviando
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.send),
                label: const Text('Crear ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
