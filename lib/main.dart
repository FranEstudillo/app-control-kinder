// This line is already correct and points to the correct package.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // este es el controlador de las Tabs
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // App bar es el widget que agrega las pestañas desde aqui lo puedo ajustar
        appBar: AppBar(
          backgroundColor: Colors.amber,
          title: Text('Mi primer ABC', style: TextStyle(color: Colors.white)),
          bottom: TabBar(
            tabs: [
              //aquí se agregan las pestañas
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.settings), text: 'Opciones'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.blueGrey[600],
          ),
        ),
        // desde aquí se controla la vista de las tabs
        body: TabBarView(
          children: [
            // Reemplazamos el widget Center por un GridView para mostrar las tarjetas.
            GridView.count(
              crossAxisCount: 2, // Esto define que habrá 2 columnas.
              padding: const EdgeInsets.all(
                16.0,
              ), // Espaciado exterior de la cuadrícula.
              crossAxisSpacing: 16.0, // Espaciado horizontal entre tarjetas.
              mainAxisSpacing: 16.0, // Espaciado vertical entre tarjetas.
              children: <Widget>[
                // Tarjeta de ejemplo para un alumno.
                // Puedes copiar y pegar este widget Card para agregar más alumnos.
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AlumnosScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(
                    10.0,
                  ), // Corrección: El radio debe coincidir con el de la Card para un efecto visual correcto.
                  // Aquí se ajusta la card de Alumnos
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.amber,
                          child: Icon(
                            Icons.group,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Alumnos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Center(child: Text("Settings Screen")),
          ],
        ),
      ),
    );
  }
}

// 1. Creamos una clase para modelar los datos de un alumno.
// Esto hace que el código sea más organizado y fácil de leer.
class Alumno {
  final String nombre;
  final String grado;
  final String? fotoPath; // Cambiamos a fotoPath para guardar la ruta local

  const Alumno({required this.nombre, required this.grado, this.fotoPath});
}

class AlumnosScreen extends StatefulWidget {
  const AlumnosScreen({super.key});

  @override
  State<AlumnosScreen> createState() => _AlumnosScreenState();
}

class _AlumnosScreenState extends State<AlumnosScreen> {
  // 2. Movemos la lista al estado para poder modificarla.
  final List<Alumno> _alumnos = [
    const Alumno(nombre: 'Ana García', grado: 'Kinder 2'),
    const Alumno(nombre: 'Luis Fernández', grado: 'Maternal'),
    const Alumno(nombre: 'Sofía Martínez', grado: 'Kinder 3'),
    const Alumno(nombre: 'Carlos Rodríguez', grado: 'Kinder 1'),
    const Alumno(nombre: 'Elena Gómez', grado: 'Kinder 2'),
    const Alumno(nombre: 'Javier Pérez', grado: 'Maternal'),
  ];

  void _agregarAlumno(Alumno alumno) {
    setState(() {
      _alumnos.add(alumno);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Alumnos'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      // 3. Usamos SingleChildScrollView para que la tabla sea desplazable
      // si el contenido es más ancho que la pantalla.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // 4. Usamos ConstrainedBox para asegurar que la tabla tenga un ancho mínimo
            // igual al de la pantalla, haciendo que se estire para ocupar todo el espacio.
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 38.0,
                // Definimos las columnas de nuestra tabla
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
                ],
                // Mapeamos la lista de alumnos a filas en la tabla
                rows: _alumnos.map((alumno) {
                  return DataRow(
                    // Se elimina onSelectChanged para quitar el checkbox automático.
                    // En su lugar, se agrega un onTap a cada DataCell.
                    cells: [
                      DataCell(
                        // Usamos un CircleAvatar como marcador de posición para la foto
                        CircleAvatar(
                          // Si hay una ruta de foto, la mostramos. Si no, mostramos el ícono.
                          backgroundImage: alumno.fotoPath != null
                              ? FileImage(File(alumno.fotoPath!))
                              : null,
                          backgroundColor: Colors.amber[100],
                          child: alumno.fotoPath == null
                              ? const Icon(Icons.person, color: Colors.amber)
                              : null,
                        ),
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
                      DataCell(
                        Text(alumno.nombre),
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
                      DataCell(
                        Text(alumno.grado),
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
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navegamos al formulario y esperamos a que nos devuelva un nuevo alumno.
          final nuevoAlumno = await Navigator.push<Alumno>(
            context,
            MaterialPageRoute(
              builder: (context) => const AgregarAlumnoScreen(),
            ),
          );

          // Si recibimos un alumno, lo agregamos a la lista.
          if (nuevoAlumno != null) {
            _agregarAlumno(nuevoAlumno);
          }
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

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
              backgroundImage: alumno.fotoPath != null
                  ? FileImage(File(alumno.fotoPath!))
                  : null,
              backgroundColor: Colors.amber[100],
              child: alumno.fotoPath == null
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
                // Aquí irá la lógica para la información de pagos.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad de pagos próximamente.'),
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

// Pantalla con el formulario para agregar un nuevo alumno
class AgregarAlumnoScreen extends StatefulWidget {
  const AgregarAlumnoScreen({super.key});

  @override
  State<AgregarAlumnoScreen> createState() => _AgregarAlumnoScreenState();
}

class _AgregarAlumnoScreenState extends State<AgregarAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  String? _selectedGrado;
  final List<String> _grados = ['Maternal', 'Kinder 1', 'Kinder 2', 'Kinder 3'];
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

  void _guardarAlumno() {
    // Validamos que el formulario esté correcto.
    if (_formKey.currentState!.validate()) {
      final nuevoAlumno = Alumno(
        nombre: _nombreController.text,
        grado: _selectedGrado!,
        fotoPath: _imageFile?.path, // Guardamos la ruta de la imagen
      );
      // Si es válido, cerramos la pantalla y devolvemos el nuevo alumno.
      Navigator.pop(context, nuevoAlumno);
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
