import 'package:flutter/material.dart';

class Estado {
  static const _etiquetas = {
    'nuevo': 'Nuevo',
    'en_proceso': 'En proceso',
    'a_presupuestar': 'A presupuestar',
    'presupuesto_aprobado': 'Presupuesto aprobado',
    'presupuesto_rechazado': 'Presupuesto rechazado',
    'resuelto': 'Resuelto',
    'cerrado': 'Cerrado',
  };

  static String etiqueta(String estado) => _etiquetas[estado] ?? estado;

  static Color color(String estado) {
    switch (estado) {
      case 'nuevo':
        return const Color(0xFF2563EB);
      case 'en_proceso':
        return const Color(0xFFD97706);
      case 'a_presupuestar':
        return const Color(0xFF7C3AED);
      case 'presupuesto_aprobado':
        return const Color(0xFF4F46E5);
      case 'presupuesto_rechazado':
        return const Color(0xFFDC2626);
      case 'resuelto':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class Ticket {
  final String id;
  final int numero;
  final String origen;
  final String empleado;
  final String equipo;
  final String descripcion;
  final String urgencia;
  final String estado;
  final String? notaResolucion;
  final String? materiales;
  final String? presupuestoDetalle;
  final double? presupuestoMonto;
  final DateTime creadoEn;
  final DateTime? tomadoEn;
  final DateTime? resueltoEn;

  Ticket.desdeMapa(Map<String, dynamic> m)
      : id = m['id'] as String,
        numero = m['numero'] as int,
        origen = m['origen'] as String,
        empleado = m['empleado'] as String,
        equipo = m['equipo'] as String,
        descripcion = m['descripcion'] as String,
        urgencia = m['urgencia'] as String,
        estado = m['estado'] as String,
        notaResolucion = m['nota_resolucion'] as String?,
        materiales = m['materiales'] as String?,
        presupuestoDetalle = m['presupuesto_detalle'] as String?,
        presupuestoMonto = (m['presupuesto_monto'] as num?)?.toDouble(),
        creadoEn = DateTime.parse(m['creado_en'] as String).toLocal(),
        tomadoEn = _fecha(m['tomado_en']),
        resueltoEn = _fecha(m['resuelto_en']);

  static DateTime? _fecha(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  String get numeroTexto => '#${numero.toString().padLeft(4, '0')}';
  bool get esUrgente => urgencia == 'urgente';
  bool get esDeSistemas => origen == 'sistemas';

  /// Tickets que todavía requieren algo de Sistemas o del farmacéutico.
  bool get estaAbierto => const {
        'nuevo',
        'en_proceso',
        'a_presupuestar',
        'presupuesto_aprobado',
      }.contains(estado);
}

/// Etiqueta de color con el estado del ticket.
class ChipEstado extends StatelessWidget {
  final String estado;
  const ChipEstado(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = Estado.color(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(
        Estado.etiqueta(estado),
        style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
