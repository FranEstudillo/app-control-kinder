import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alumno.dart';
import 'agregar_alumno_screen.dart';
import 'alumno_detalle_screen.dart';
import '../utils/color_utils.dart';

class AlumnosScreen extends StatefulWidget {
  const AlumnosScreen({super.key});

  @override
  State<AlumnosScreen> createState() => _AlumnosScreenState();
}

class _AlumnosScreenState extends State<AlumnosScreen> {
  // Variable para guardar el grado seleccionado en el filtro
  String? _filtroGrado;
  final List<String> _grados = ['Maternal', 'Kínder 1', 'Kínder 2', 'Kínder 3'];

  @override
  Widget build(BuildContext context) {
    // La consulta a Firestore ahora es dinámica
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('alumnos')
        .orderBy('nombre');

    // Si hay un grado seleccionado en el filtro, añadimos la condición a la consulta
    if (_filtroGrado != null) {
      query = query.where('grado', isEqualTo: _filtroGrado);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Alumnos Registrados'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- WIDGET DEL FILTRO ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroGrado,
                    hint: const Text('Filtrar por grado'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.filter_alt),
                    ),
                    items: _grados.map((grado) {
                      return DropdownMenuItem(value: grado, child: Text(grado));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _filtroGrado = newValue;
                      });
                    },
                  ),
                ),
                // Botón para limpiar el filtro
                if (_filtroGrado != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Limpiar filtro',
                    onPressed: () {
                      setState(() {
                        _filtroGrado = null;
                      });
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- LISTA DE ALUMNOS (AHORA CON LISTVIEW) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay alumnos registrados que coincidan con el filtro.',
                    ),
                  );
                }

                final alumnos = snapshot.data!.docs
                    .map((doc) => Alumno.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: alumnos.length,
                  itemBuilder: (context, index) {
                    final alumno = alumnos[index];
                    // 2. Obtenemos el color para el grado del alumno
                    final colorGrado = getColorForGrado(alumno.grado);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      // 1. Añadimos una propiedad shape para personalizar el borde
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          8.0,
                        ), // Puedes ajustar el radio si quieres más o menos redondeado
                        // 2. Definimos el borde superior con el color del grado
                        side: BorderSide(
                          color: getColorForGrado(alumno.grado),
                          width: 1.2,
                        ),
                      ),

                      child: ListTile(
                        leading: CircleAvatar(
                          // 3. Aplicamos el color y un tono más claro de fondo
                          backgroundColor: colorGrado.withOpacity(0.2),
                          child: Text(
                            alumno.nombre.substring(0, 1),
                            style: TextStyle(
                              color: colorGrado,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(alumno.nombre),
                        subtitle: Text(alumno.grado),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AlumnoDetalleScreen(alumno: alumno),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AgregarAlumnoScreen(),
            ),
          );
        },
        tooltip: 'Agregar Alumno',
        backgroundColor: Colors.blue.shade900,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
