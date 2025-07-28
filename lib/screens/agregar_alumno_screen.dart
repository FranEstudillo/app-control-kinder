import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
//modelos
import '../models/alumno.dart';
//firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AgregarAlumnoScreen extends StatefulWidget {
  const AgregarAlumnoScreen({super.key});

  @override
  State<AgregarAlumnoScreen> createState() => _AgregarAlumnoScreenState();
}

class _AgregarAlumnoScreenState extends State<AgregarAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  String? _selectedGrado;
  final List<String> _grados = ['Maternal', 'Kínder 1', 'Kínder 2', 'Kínder 3'];
  File? _imageFile; // Variable para guardar la foto seleccionada
  bool _isPickerActive = false; // Flag para evitar múltiples llamadas al picker

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  // Nueva función para seleccionar imagen de la galería
  Future<void> _pickImage() async {
    // 1. Si ya hay una operación de selección en curso, no hacemos nada.
    if (_isPickerActive) return;

    final picker = ImagePicker();
    try {
      // 2. Marcamos el picker como activo.
      _isPickerActive = true;
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } finally {
      // 3. Nos aseguramos de marcar el picker como inactivo al finalizar.
      _isPickerActive = false;
    }
  }

  Future<void> _guardarAlumno() async {
    // Validamos que el formulario esté correcto.
    if (_formKey.currentState!.validate()) {
      String? fotoUrl;

      // 1. Subir la imagen a Firebase Storage si se seleccionó una.
      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(
          'fotos_alumnos/$fileName',
        );

        try {
          await ref.putFile(_imageFile!);
          fotoUrl = await ref.getDownloadURL();
        } catch (e) {
          if (!mounted) return;
          // Manejar error de subida
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al subir la foto: $e')));
          return;
        }
      }

      // 2. Crear el objeto Alumno y guardarlo en Firestore.
      final nuevoAlumno = Alumno(
        nombre: _nombreController.text,
        grado: _selectedGrado!,
        fotoUrl: fotoUrl,
      );

      await FirebaseFirestore.instance
          .collection('alumnos')
          .add(nuevoAlumno.toJson());

      // 3. Cerrar la pantalla del formulario.
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Nuevo Alumno'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Widget para seleccionar y mostrar la foto del alumno
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      // Mostramos la imagen seleccionada o un ícono de persona
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : null,
                      child: _imageFile == null
                          ? Icon(
                              Icons.person,
                              color: Colors.grey[800],
                              size: 50,
                            )
                          : null,
                    ),
                    // Icono de cámara para seleccionar la imagen
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.amber,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Campo de texto para el nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el nombre del alumno';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Menú desplegable para el grado
              DropdownButtonFormField<String>(
                value: _selectedGrado,
                decoration: const InputDecoration(
                  labelText: 'Grado',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Seleccione un grado'),
                items: _grados.map((String grado) {
                  return DropdownMenuItem<String>(
                    value: grado,
                    child: Text(grado),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedGrado = newValue),
                validator: (value) =>
                    value == null ? 'Por favor, seleccione un grado' : null,
              ),
              const Spacer(),
              // Botón para guardar
              ElevatedButton(
                onPressed: _guardarAlumno,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Guardar Alumno'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
