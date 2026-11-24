import 'package:flutter/material.dart';

import '../supa.dart';

/// Terminal 1 es la madre (servidor) y no tiene impresora de tickets.
/// Las terminales 2 a 7 tienen computadora e impresora de tickets.
const _cantidadTerminales = 7;

String _nombreTerminal(int n) => n == 1 ? 'Terminal 1 (madre)' : 'Terminal $n';

const _otrosEquipos = [
  'Internet / WiFi',
  'Sistema de ventas',
  'Lector de códigos',
  'Teléfono',
  'Otro',
];

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
  final _focoEquipo = FocusNode();
  bool _urgente = false;
  bool _enviando = false;
  int? _terminal; // terminal elegida
  bool _impresora = false; // true = la impresora de tickets de esa terminal

  void _ponerEquipo(String texto) {
    _equipo.text = texto;
    _equipo.selection = TextSelection.collapsed(offset: texto.length);
  }

  void _elegirTerminal(int n) {
    setState(() {
      _terminal = n;
      _impresora = false;
    });
    _ponerEquipo(_nombreTerminal(n));
  }

  void _elegirParte(bool impresora) {
    setState(() => _impresora = impresora);
    final base = _nombreTerminal(_terminal!);
    _ponerEquipo(impresora ? '$base - Impresora de tickets' : base);
  }

  void _elegirOtro(String e) {
    setState(() => _terminal = null);
    if (e == 'Otro') {
      // Que escriban qué equipo es.
      _equipo.clear();
      _focoEquipo.requestFocus();
    } else {
      _ponerEquipo(e);
    }
  }

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
    _focoEquipo.dispose();
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
              Text('¿Qué equipo tiene el problema?',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var n = 1; n <= _cantidadTerminales; n++)
                    ChoiceChip(
                      label: Text(n == 1 ? 'Terminal 1 (madre)' : 'Terminal $n'),
                      selected: _terminal == n,
                      onSelected: (_) => _elegirTerminal(n),
                    ),
                ],
              ),
              // Terminales 2 a 7: ¿la compu o la impresora de tickets?
              if (_terminal != null && _terminal != 1) ...[
                const SizedBox(height: 12),
                Text('¿Qué parte de la Terminal $_terminal?',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                        value: false, icon: Icon(Icons.computer), label: Text('Computadora')),
                    ButtonSegment(
                        value: true,
                        icon: Icon(Icons.receipt_long),
                        label: Text('Impresora de tickets')),
                  ],
                  showSelectedIcon: false,
                  selected: {_impresora},
                  onSelectionChanged: (v) => _elegirParte(v.first),
                ),
              ],
              const SizedBox(height: 12),
              Text('Otros equipos', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in _otrosEquipos)
                    ActionChip(label: Text(e), onPressed: () => _elegirOtro(e)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _equipo,
                focusNode: _focoEquipo,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Equipo',
                  hintText: 'Ej: Terminal 3',
                  prefixIcon: Icon(Icons.computer),
                ),
                validator: _obligatorio,
              ),
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
