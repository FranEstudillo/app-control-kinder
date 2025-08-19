// lib/models/movimiento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Movimiento {
  final String id; // ID del documento de Firestore
  final double monto;
  final Timestamp fecha;
  final String fuente;
  final String tipo; // 'ingreso' o 'gasto'
  final String rubro;
  final String? nombreAlumno; // ✅ Nueva propiedad

  Movimiento({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.fuente,
    required this.tipo,
    required this.rubro,
    this.nombreAlumno, // ✅ Nuevo parámetro opcional en el constructor
  });
}
