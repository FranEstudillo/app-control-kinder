import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Creamos una clase para modelar los datos de un alumno.
// Esto hace que el código sea más organizado y fácil de leer.
class Alumno {
  final String nombre;
  final String grado;
  final String? fotoUrl; // URL de la imagen en la nube
  final String? id; // ID del documento de Firestore
  final String? tallaBata;
  final Map<String, dynamic>? piezasUniforme;

  const Alumno({
    required this.nombre,
    required this.grado,
    this.fotoUrl,
    this.id,
    this.tallaBata,
    this.piezasUniforme,
  });
  // ✅ AGREGA ESTE MÉTODO COMPLETO
  Alumno copyWith({
    String? id,
    String? nombre,
    String? grado,
    // String? fotoUrl,
    String? tallaBata,
    Map<String, dynamic>? piezasUniforme,
  }) {
    return Alumno(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      grado: grado ?? this.grado,
      // fotoUrl: fotoUrl ?? this.fotoUrl,
      tallaBata: tallaBata ?? this.tallaBata,
      piezasUniforme: piezasUniforme ?? this.piezasUniforme,
    );
  }

  // Convierte un objeto Alumno a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'grado': grado,
      'fotoUrl': fotoUrl,
      'tallaBata': tallaBata,
      'piezasUniforme': piezasUniforme,
    };
  }

  // Crea un objeto Alumno desde un documento de Firestore
  factory Alumno.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Alumno(
      id: doc.id,
      nombre: data['nombre'],
      grado: data['grado'],
      fotoUrl: data['fotoUrl'],
      tallaBata: data['tallaBata'],
      piezasUniforme: data['piezasUniforme'],
    );
  }
}
