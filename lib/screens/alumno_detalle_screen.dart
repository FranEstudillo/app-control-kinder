import 'package:flutter/material.dart';
//modelos
import 'package:app_control_kinder_v4/models/alumno.dart';
//pantallas
import 'package:app_control_kinder_v4/screens/pagos_screen.dart';

// 2. Creamos la nueva pantalla para mostrar los detalles del alumno.
class AlumnoDetalleScreen extends StatelessWidget {
  final Alumno alumno;

  const AlumnoDetalleScreen({super.key, required this.alumno});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(alumno.nombre),
        backgroundColor: Colors.amber,
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
              backgroundImage: alumno.fotoUrl != null
                  ? NetworkImage(alumno.fotoUrl!)
                  : null,
              backgroundColor: Colors.amber[100],
              child: alumno.fotoUrl == null
                  ? const Icon(Icons.person, size: 100, color: Colors.amber)
                  : null,
            ),
            const SizedBox(height: 24),
            // Nombre del alumno
            Text(
              alumno.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Grado del alumno
            Text(
              'Grado: ${alumno.grado}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
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
                    builder: (context) => PagosScreen(alumno: alumno),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
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
