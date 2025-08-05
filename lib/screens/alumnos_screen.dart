import 'package:flutter/material.dart';
//firestore
import 'package:cloud_firestore/cloud_firestore.dart';
//pantallas
import 'package:app_control_kinder_v4/screens/alumno_detalle_screen.dart';
import 'package:app_control_kinder_v4/screens/pagos_screen.dart';
import 'package:app_control_kinder_v4/screens/agregar_alumno_screen.dart';
//modelos
import '../models/alumno.dart';

class AlumnosScreen extends StatefulWidget {
  const AlumnosScreen({super.key});

  @override
  State<AlumnosScreen> createState() => _AlumnosScreenState();
}

class _AlumnosScreenState extends State<AlumnosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Alumnos'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      // Usamos StreamBuilder para escuchar los datos de Firestore en tiempo real.
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('alumnos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Imprimimos el error en la consola para un mejor diagnóstico.
            print('Error al leer de Firestore: ${snapshot.error}');
            return const Center(child: Text('Ocurrió un error'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay alumnos registrados.'));
          }

          final alumnos = snapshot.data!.docs
              .map((doc) => Alumno.fromFirestore(doc))
              .toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 20.0,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Foto',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Nombre',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Grado',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Pagos',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: alumnos.map((alumno) {
                      return DataRow(
                        cells: [
                          DataCell(
                            CircleAvatar(
                              backgroundImage: alumno.fotoUrl != null
                                  ? NetworkImage(alumno.fotoUrl!)
                                  : null,
                              backgroundColor: Colors.amber[100],
                              child: alumno.fotoUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.amber,
                                    )
                                  : null,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AlumnoDetalleScreen(alumno: alumno),
                                ),
                              ).then((huboCambios) {
                                // ✅ Añade este bloque .then()
                                // Si la pantalla de detalle devolvió 'true'...
                                if (huboCambios == true) {
                                  // ...le decimos a esta pantalla que se refresque para cargar los nuevos totales.
                                  setState(() {});
                                }
                              });
                            },
                          ),
                          DataCell(
                            Text(alumno.nombre),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AlumnoDetalleScreen(alumno: alumno),
                                ),
                              ).then((huboCambios) {
                                // ✅ Añade este bloque .then()
                                // Si la pantalla de detalle devolvió 'true'...
                                if (huboCambios == true) {
                                  // ...le decimos a esta pantalla que se refresque para cargar los nuevos totales.
                                  setState(() {});
                                }
                              });
                            },
                          ),
                          DataCell(
                            Text(alumno.grado),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AlumnoDetalleScreen(alumno: alumno),
                                ),
                              ).then((huboCambios) {
                                // ✅ Añade este bloque .then()
                                // Si la pantalla de detalle devolvió 'true'...
                                if (huboCambios == true) {
                                  // ...le decimos a esta pantalla que se refresque para cargar los nuevos totales.
                                  setState(() {});
                                }
                              });
                            },
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.payment,
                                color: Colors.amber,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PagosScreen(alumno: alumno),
                                  ),
                                ).then((huboCambios) {
                                  // ✅ Añade este bloque .then()
                                  // Si la pantalla de detalle devolvió 'true'...
                                  if (huboCambios == true) {
                                    // ...le decimos a esta pantalla que se refresque para cargar los nuevos totales.
                                    setState(() {});
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navegamos al formulario y esperamos a que nos devuelva un nuevo alumno.
          await Navigator.push<Alumno>(
            context,
            MaterialPageRoute(
              builder: (context) => const AgregarAlumnoScreen(),
            ),
          );
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
