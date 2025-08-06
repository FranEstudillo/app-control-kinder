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
  final String? nombrePadre;
  final String? contactoEmergencia1;
  final String? contactoEmergencia2;

  const Alumno({
    required this.nombre,
    required this.grado,
    this.fotoUrl,
    this.id,
    this.tallaBata,
    this.piezasUniforme,
    this.nombrePadre,
    this.contactoEmergencia1,
    this.contactoEmergencia2,
  });
  // ✅ AGREGA ESTE MÉTODO COMPLETO
  Alumno copyWith({
    String? id,
    String? nombre,
    String? grado,
    // String? fotoUrl,
    String? tallaBata,
    Map<String, dynamic>? piezasUniforme,
    String? nombrePadre,
    String? contactoEmergencia1,
    String? contactoEmergencia2,
  }) {
    return Alumno(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      grado: grado ?? this.grado,
      // fotoUrl: fotoUrl ?? this.fotoUrl,
      tallaBata: tallaBata ?? this.tallaBata,
      piezasUniforme: piezasUniforme ?? this.piezasUniforme,
      nombrePadre: nombrePadre ?? this.nombrePadre,
      contactoEmergencia1: contactoEmergencia1 ?? this.contactoEmergencia1,
      contactoEmergencia2: contactoEmergencia2 ?? this.contactoEmergencia2,
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
      'nombrePadre': nombrePadre,
      'contactoEmergencia1': contactoEmergencia1,
      'contactoEmergencia2': contactoEmergencia2,
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
      nombrePadre: data['nombrePadre'],
      contactoEmergencia1: data['contactoEmergencia1'],
      contactoEmergencia2: data['contactoEmergencia2'],
    );
  }
}
