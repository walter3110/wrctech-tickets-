import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../supa.dart';

/// Trabajo que hace Sistemas sin que nadie lo pida (ej. cambio de teclados).
class NuevoTrabajoPage extends StatefulWidget {
  const NuevoTrabajoPage({super.key});

  @override
  State<NuevoTrabajoPage> createState() => _NuevoTrabajoPageState();
}

class _NuevoTrabajoPageState extends State<NuevoTrabajoPage> {
  final _form = GlobalKey<FormState>();
  final _equipo = TextEditingController();
  final _descripcion = TextEditingController();
  final _materiales = TextEditingController();
  bool _yaHecho = true;
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    final descripcion = _descripcion.text.trim();
    final materiales = _materiales.text.trim();
    try {
      final fila = await supabase
          .from('tickets')
          .insert({
            'origen': 'sistemas',
            'empleado': 'Sistemas',
            'equipo': _equipo.text.trim(),
            'descripcion': descripcion,
            'estado': _yaHecho ? 'resuelto' : 'nuevo',
            if (_yaHecho) 'nota_resolucion': descripcion,
            if (materiales.isNotEmpty) 'materiales': materiales,
          })
          .select('numero')
          .single();
      if (!mounted) return;
      final numero = (fila['numero'] as int).toString().padLeft(4, '0');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Trabajo #$numero ${_yaHecho ? 'registrado' : 'agendado'}'),
      ));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo guardar. Revisá la conexión.'),
      ));
    }
  }

  @override
  void dispose() {
    _equipo.dispose();
    _descripcion.dispose();
    _materiales.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo trabajo')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, icon: Icon(Icons.check), label: Text('Ya lo hice')),
                  ButtonSegment(value: false, icon: Icon(Icons.schedule), label: Text('Pendiente')),
                ],
                showSelectedIcon: false,
                selected: {_yaHecho},
                onSelectionChanged: (v) => setState(() => _yaHecho = v.first),
              ),
              const SizedBox(height: 20),
              SelectorEquipo(controller: _equipo, titulo: '¿En qué equipo?'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descripcion,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: _yaHecho ? '¿Qué hiciste?' : '¿Qué vas a hacer?',
                  hintText: 'Ej: cambio de teclado y mouse',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Completá este dato' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _materiales,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Materiales (opcional)',
                  hintText: 'Ej: 1 teclado, 1 mouse',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.save),
                label: Text(_yaHecho ? 'Registrar trabajo' : 'Agendar trabajo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
