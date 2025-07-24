import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para los datos de un gasto.
class Gasto {
  final String id;
  final double monto;
  final String fuente; // 'Efectivo' o 'Tarjeta'
  final Timestamp fechaGasto;

  const Gasto({
    required this.id,
    required this.monto,
    required this.fuente,
    required this.fechaGasto,
  });

  factory Gasto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Gasto(
      id: doc.id,
      monto: (data['monto'] as num).toDouble(),
      fuente: data['fuente'] as String,
      fechaGasto: data['fechaGasto'] as Timestamp,
    );
  }
}
