import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pago.dart';

Future<Map<String, double>> getTotalesColegiaturasYGastos() async {
  // Colegiaturas
  final pagosSnapshot = await FirebaseFirestore.instance
      .collectionGroup('pagos')
      .where('rubro', isEqualTo: 'Colegiatura')
      .get();
  double totalGeneral = 0;
  double totalEfectivo = 0;
  double totalTarjeta = 0;
  for (final doc in pagosSnapshot.docs) {
    final pago = Pago.fromFirestore(doc);
    totalGeneral += pago.monto;
    if (pago.metodoPago == 'Efectivo') totalEfectivo += pago.monto;
    if (pago.metodoPago == 'Tarjeta') totalTarjeta += pago.monto;
  }

  // Gastos
  final gastosSnapshot = await FirebaseFirestore.instance
      .collection('gastos')
      .get();
  double totalGastosEfectivo = 0;
  double totalGastosTarjeta = 0;
  for (final doc in gastosSnapshot.docs) {
    final data = doc.data();
    final monto = (data['monto'] as num).toDouble();
    final fuente = data['fuente'] as String? ?? '';
    if (fuente == 'Efectivo') totalGastosEfectivo += monto;
    if (fuente == 'Tarjeta') totalGastosTarjeta += monto;
  }

  return {
    'totalGeneral': totalGeneral - totalGastosEfectivo - totalGastosTarjeta,
    'totalEfectivo': totalEfectivo - totalGastosEfectivo,
    'totalTarjeta': totalTarjeta - totalGastosTarjeta,
  };
}
