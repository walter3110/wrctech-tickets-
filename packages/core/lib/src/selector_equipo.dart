import 'package:flutter/material.dart';

/// Terminal 1 es la madre (servidor) y no tiene impresora de tickets.
/// Las terminales 2 a 7 tienen computadora e impresora de tickets.
const cantidadTerminales = 7;

String nombreTerminal(int n) => n == 1 ? 'Terminal 1 (madre)' : 'Terminal $n';

const otrosEquipos = [
  'Internet / WiFi',
  'Sistema de ventas',
  'Lector de códigos',
  'Teléfono',
  'Otro',
];

/// Botones rápidos para elegir el equipo + campo de texto editable.
class SelectorEquipo extends StatefulWidget {
  final TextEditingController controller;
  final String titulo;
  const SelectorEquipo({
    super.key,
    required this.controller,
    this.titulo = '¿Qué equipo tiene el problema?',
  });

  @override
  State<SelectorEquipo> createState() => _SelectorEquipoState();
}

class _SelectorEquipoState extends State<SelectorEquipo> {
  final _foco = FocusNode();
  int? _terminal;
  bool _impresora = false;

  void _poner(String texto) {
    widget.controller.text = texto;
    widget.controller.selection = TextSelection.collapsed(offset: texto.length);
  }

  void _elegirTerminal(int n) {
    setState(() {
      _terminal = n;
      _impresora = false;
    });
    _poner(nombreTerminal(n));
  }

  void _elegirParte(bool impresora) {
    setState(() => _impresora = impresora);
    final base = nombreTerminal(_terminal!);
    _poner(impresora ? '$base - Impresora de tickets' : base);
  }

  void _elegirOtro(String e) {
    setState(() => _terminal = null);
    if (e == 'Otro') {
      widget.controller.clear();
      _foco.requestFocus();
    } else {
      _poner(e);
    }
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.titleSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.titulo, style: titulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var n = 1; n <= cantidadTerminales; n++)
              ChoiceChip(
                label: Text(nombreTerminal(n)),
                selected: _terminal == n,
                onSelected: (_) => _elegirTerminal(n),
              ),
          ],
        ),
        if (_terminal != null && _terminal != 1) ...[
          const SizedBox(height: 12),
          Text('¿Qué parte de la Terminal $_terminal?', style: titulo),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, icon: Icon(Icons.computer), label: Text('Computadora')),
              ButtonSegment(
                  value: true, icon: Icon(Icons.receipt_long), label: Text('Impresora de tickets')),
            ],
            showSelectedIcon: false,
            selected: {_impresora},
            onSelectionChanged: (v) => _elegirParte(v.first),
          ),
        ],
        const SizedBox(height: 12),
        Text('Otros equipos', style: titulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in otrosEquipos)
              ActionChip(label: Text(e), onPressed: () => _elegirOtro(e)),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: widget.controller,
          focusNode: _foco,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Equipo',
            hintText: 'Ej: Terminal 3',
            prefixIcon: Icon(Icons.computer),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Completá este dato' : null,
        ),
      ],
    );
  }
}
