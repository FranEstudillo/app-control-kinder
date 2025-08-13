import 'package:flutter/material.dart';
//modelos
import 'package:app_control_kinder_v4/models/alumno.dart';
//pantallas
import 'package:app_control_kinder_v4/screens/pagos_screen.dart';
//firebase
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
//utils
import 'package:app_control_kinder_v4/utils/color_utils.dart';

// 2. Creamos la nueva pantalla para mostrar los detalles del alumno.
class AlumnoDetalleScreen extends StatefulWidget {
  final Alumno alumno;

  const AlumnoDetalleScreen({super.key, required this.alumno});

  @override
  State<AlumnoDetalleScreen> createState() => _AlumnoDetalleScreenState();
}

class _AlumnoDetalleScreenState extends State<AlumnoDetalleScreen> {
  late Alumno alumnoMostrado; // ✅ Declara la nueva variable aquí
  final List<String> _grados = ['Maternal', 'Kínder 1', 'Kínder 2', 'Kínder 3'];

  @override
  void initState() {
    super.initState();
    // Copiamos el alumno original a nuestra variable de estado
    alumnoMostrado = widget.alumno;
  }

  void _mostrarPopupEditar(BuildContext context, Alumno alumno) {
    final TextEditingController nombreController = TextEditingController(
      text: alumno.nombre,
    );
    final TextEditingController nombrePadreController = TextEditingController(
      text: alumno.nombrePadre,
    );
    final TextEditingController contactoEmergencia1Controller =
        TextEditingController(text: alumno.contactoEmergencia1);
    final TextEditingController contactoEmergencia2Controller =
        TextEditingController(text: alumno.contactoEmergencia2);
    String? gradoSeleccionado = alumno.grado;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Editar Alumno"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: "Nombre del Alumno",
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ESTE ES EL CÓDIGO DEL DESPLEGABLE
                    DropdownButtonFormField<String>(
                      value: gradoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Grado',
                        border: OutlineInputBorder(),
                      ),
                      items: _grados.map((String grado) {
                        return DropdownMenuItem<String>(
                          value: grado,
                          child: Text(grado),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() {
                          gradoSeleccionado = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nombrePadreController,
                      decoration: const InputDecoration(
                        labelText: "Nombre del Padre o Tutor",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contactoEmergencia1Controller,
                      decoration: const InputDecoration(
                        labelText: "Contacto de Emergencia 1",
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contactoEmergencia2Controller,
                      decoration: const InputDecoration(
                        labelText: "Contacto de Emergencia 2 (Opcional)",
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.of(context).pop(),
                ),

                // ESTE ES EL BOTÓN "GUARDAR" QUE YA USA LA VARIABLE CORRECTA
                // En el onPressed del ElevatedButton de tu popup de edición
                ElevatedButton(
                  child: const Text("Guardar"),
                  onPressed: () async {
                    // 1. Actualizamos únicamente el documento del alumno (esto es lo único necesario)
                    await FirebaseFirestore.instance
                        .collection('alumnos')
                        .doc(alumnoMostrado.id)
                        .update({
                          'nombre': nombreController.text,
                          'grado': gradoSeleccionado,
                          'nombrePadre': nombrePadreController.text,
                          'contactoEmergencia1':
                              contactoEmergencia1Controller.text,
                          'contactoEmergencia2':
                              contactoEmergencia2Controller.text,
                        });

                    // 2. Cerramos el popup
                    Navigator.of(context).pop();

                    // 3. Cerramos la pantalla de detalle y enviamos 'true' como señal de éxito
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 2. Aplicamos el color dinámicamente
        backgroundColor: getColorForGrado(alumnoMostrado.grado),
        title: Text(alumnoMostrado.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Aquí va la lógica para abrir el popup de edición.
              // Usaremos la función _mostrarPopupEditar que definimos en el plan.
              _mostrarPopupEditar(context, alumnoMostrado);
            },
          ),
        ],
        // backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Foto del alumno
            CircleAvatar(
              radius: 80,
              backgroundImage: alumnoMostrado.fotoUrl != null
                  ? NetworkImage(alumnoMostrado.fotoUrl!)
                  : null,
              backgroundColor: getColorForGrado(alumnoMostrado.grado),
              child: alumnoMostrado.fotoUrl == null
                  ? const Icon(Icons.person, size: 100, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 24),
            // Nombre del alumno
            Text(
              alumnoMostrado.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Grado del alumno
            Text(
              'Grado: ${alumnoMostrado.grado}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de Contacto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (alumnoMostrado.nombrePadre != null &&
                        alumnoMostrado.nombrePadre!.isNotEmpty) ...[
                      Text('Padre o Tutor: ${alumnoMostrado.nombrePadre}'),
                      const Divider(),
                    ],
                    if (alumnoMostrado.contactoEmergencia1 != null &&
                        alumnoMostrado.contactoEmergencia1!.isNotEmpty) ...[
                      Text('Contacto 1: ${alumnoMostrado.contactoEmergencia1}'),
                      const Divider(),
                    ],
                    if (alumnoMostrado.contactoEmergencia2 != null &&
                        alumnoMostrado.contactoEmergencia2!.isNotEmpty)
                      Text('Contacto 2: ${alumnoMostrado.contactoEmergencia2}'),
                  ],
                ),
              ),
            ),
            // Espaciador para empujar el botón hacia abajo
            const Spacer(),
            // Botón de información de pagos
            ElevatedButton(
              onPressed: () {
                // Navegamos a la pantalla de pagos del alumno.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PagosScreen(alumno: alumnoMostrado),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: getColorForGrado(alumnoMostrado.grado),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Información de Pagos'),
            ),
          ],
        ),
      ),
    );
  }
}
