// lib/models/gasto.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Gasto {
  final String? id;
  final double monto;
  final String fuente; // 'Efectivo' o 'Tarjeta'
  final String? rubro;
  final String? grado;
  final Timestamp fecha;
  final String? comentario;

  Gasto({
    this.id,
    required this.monto,
    required this.fuente,
    this.rubro,
    this.grado,
    required this.fecha,
    this.comentario,
  });

  // Método para convertir el objeto a un mapa que Firestore entiende
  Map<String, dynamic> toJson() {
    return {
      'monto': monto,
      'fuente': fuente,
      'rubro': rubro,
      'grado': grado,
      'fecha': fecha,
      'comentario': comentario,
    };
  }
}
