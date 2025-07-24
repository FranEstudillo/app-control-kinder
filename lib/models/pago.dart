import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para los datos de un pago.
class Pago {
  final String id;
  final String rubro;
  final double monto;
  final Timestamp fechaPago;
  final String metodoPago;
  final String tipo; // 'total' o 'parcial'

  const Pago({
    required this.id,
    required this.rubro,
    required this.monto,
    required this.fechaPago,
    required this.metodoPago,
    required this.tipo,
  });

  factory Pago.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Pago(
      id: doc.id,
      rubro: data['rubro'] as String,
      monto: (data['monto'] as num).toDouble(),
      fechaPago: data['fechaPago'] as Timestamp,
      metodoPago: data['metodoPago'] as String,
      // Si el campo 'tipo' no existe en documentos antiguos, lo tratamos como 'total' para mantener la compatibilidad.
      tipo: data['tipo'] as String? ?? 'total',
    );
  }
}
