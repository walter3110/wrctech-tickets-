String _dos(int n) => n.toString().padLeft(2, '0');

/// "Hoy 14:05", "Ayer 09:30" o "21/11 18:00".
String fechaCorta(DateTime d) {
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(d.year, d.month, d.day);
  final hora = '${_dos(d.hour)}:${_dos(d.minute)}';
  final diferencia = hoy.difference(dia).inDays;
  if (diferencia == 0) return 'Hoy $hora';
  if (diferencia == 1) return 'Ayer $hora';
  return '${_dos(d.day)}/${_dos(d.month)} $hora';
}
