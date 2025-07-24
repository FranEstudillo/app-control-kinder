// This line is already correct and points to the correct package.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
                // Tarjeta de Alumnos
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AlumnosScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10.0),
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
                // Tarjeta de Ingresos
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IngresosScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10.0),
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
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.monetization_on,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Ingresos',
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

// Pantalla de marcador de posición para la nueva funcionalidad de Ingresos.
class IngresosScreen extends StatelessWidget {
  const IngresosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      // Usamos StreamBuilders anidados para obtener tanto los pagos como los gastos.
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collectionGroup('pagos').snapshots(),
        builder: (context, pagosSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('gastos').snapshots(),
            builder: (context, gastosSnapshot) {
              if (pagosSnapshot.connectionState == ConnectionState.waiting ||
                  gastosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (pagosSnapshot.hasError) {
                print('Error en la consulta de grupo: ${pagosSnapshot.error}');
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Error al cargar los ingresos. Es posible que necesites crear un índice en Firestore. Revisa la consola de depuración para ver un enlace de creación de índice.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (gastosSnapshot.hasError) {
                return const Center(child: Text('Error al cargar los gastos.'));
              }

              // Calculamos los ingresos
              double totalIngresos = 0;
              double totalEfectivo = 0;
              double totalTarjeta = 0;

              if (pagosSnapshot.hasData) {
                for (var doc in pagosSnapshot.data!.docs) {
                  final pago = Pago.fromFirestore(doc);
                  totalIngresos += pago.monto;
                  if (pago.metodoPago == 'Efectivo') {
                    totalEfectivo += pago.monto;
                  } else if (pago.metodoPago == 'Tarjeta') {
                    totalTarjeta += pago.monto;
                  }
                }
              }

              // Calculamos los gastos
              double totalGastosEfectivo = 0;
              double totalGastosTarjeta = 0;
              final List<Gasto> gastos = [];

              if (gastosSnapshot.hasData) {
                for (var doc in gastosSnapshot.data!.docs) {
                  final gasto = Gasto.fromFirestore(doc);
                  gastos.add(
                    gasto,
                  ); // ¡Aquí estaba el error! Faltaba agregar el gasto a la lista.
                  if (gasto.fuente == 'Efectivo') {
                    totalGastosEfectivo += gasto.monto;
                  } else if (gasto.fuente == 'Tarjeta') {
                    totalGastosTarjeta += gasto.monto;
                  }
                }

                // Ordenamos los gastos del más reciente al más antiguo
                gastos.sort((a, b) => b.fechaGasto.compareTo(a.fechaGasto));
              }

              // Calculamos los saldos netos
              final saldoTotal =
                  totalIngresos - (totalGastosEfectivo + totalGastosTarjeta);
              final saldoEfectivo = totalEfectivo - totalGastosEfectivo;
              final saldoTarjeta = totalTarjeta - totalGastosTarjeta;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  // Columna principal para organizar tarjetas e historial
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contenedor para las tarjetas de saldo
                    Column(
                      children: [
                        _buildTotalCard(
                          title: 'Saldo Total',
                          amount: saldoTotal,
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildTotalCard(
                          title: 'Saldo en Efectivo',
                          amount: saldoEfectivo,
                          icon: Icons.money,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildTotalCard(
                          title: 'Saldo con Tarjeta',
                          amount: saldoTarjeta,
                          icon: Icons.credit_card,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Título para el historial
                    const Text(
                      'Historial de Gastos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 8),
                    // Lista expandida para el historial
                    Expanded(
                      child: gastos.isEmpty
                          ? const Center(
                              child: Text('No hay gastos registrados.'),
                            )
                          : ListView.builder(
                              itemCount: gastos.length,
                              itemBuilder: (context, index) {
                                final gasto = gastos[index];
                                final fecha = gasto.fechaGasto.toDate();
                                final fechaFormateada =
                                    "${fecha.day}/${fecha.month}/${fecha.year}";
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      child: Icon(Icons.arrow_downward),
                                    ),
                                    title: Text(
                                      '-\$${gasto.monto.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    subtitle: Text('Fuente: ${gasto.fuente}'),
                                    trailing: Text(
                                      fechaFormateada,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        tooltip: 'Registrar Gasto',
        child: const Icon(Icons.remove),
      ),
    );
  }

  // Método para mostrar el diálogo de registro de gasto.
  Future<void> _showAddExpenseDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final montoController = TextEditingController();
    String? selectedFuente;
    final List<String> fuentes = ['Efectivo', 'Tarjeta'];

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Registrar Gasto'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: montoController,
                      decoration: const InputDecoration(
                        labelText: 'Monto del Gasto',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese el monto';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor, ingrese un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedFuente,
                      decoration: const InputDecoration(
                        labelText: 'Fuente del Dinero',
                        prefixIcon: Icon(Icons.source),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Seleccione la fuente'),
                      items: fuentes.map((String fuente) {
                        return DropdownMenuItem<String>(
                          value: fuente,
                          child: Text(fuente),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() => selectedFuente = newValue);
                      },
                      validator: (value) => value == null
                          ? 'Por favor, seleccione una fuente'
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar Gasto'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final gastoData = {
                    'monto': double.parse(montoController.text),
                    'fuente': selectedFuente!,
                    'fechaGasto': Timestamp.now(),
                  };
                  try {
                    await FirebaseFirestore.instance
                        .collection('gastos')
                        .add(gastoData);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gasto guardado correctamente.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar el gasto: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Widget reutilizable para mostrar una tarjeta de total.
  Widget _buildTotalCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
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
  final String? fotoUrl; // Ahora guardamos la URL de la imagen en la nube
  final String? id; // ID del documento de Firestore

  const Alumno({
    required this.nombre,
    required this.grado,
    this.fotoUrl,
    this.id,
  });

  // Convierte un objeto Alumno a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {'nombre': nombre, 'grado': grado, 'fotoUrl': fotoUrl};
  }

  // Crea un objeto Alumno desde un documento de Firestore
  factory Alumno.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Alumno(
      id: doc.id,
      nombre: data['nombre'],
      grado: data['grado'],
      fotoUrl: data['fotoUrl'],
    );
  }
}

// Modelo para los datos de un gasto.
class Gasto {
  final String id;
  final double monto;
  final String fuente; // 'Efectivo' o 'Tarjeta'
  final Timestamp fechaGasto;

  const Gasto({
    required this.id,
    required this.monto,
    required this.fuente,
    required this.fechaGasto,
  });

  factory Gasto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Gasto(
      id: doc.id,
      monto: (data['monto'] as num).toDouble(),
      fuente: data['fuente'] as String,
      fechaGasto: data['fechaGasto'] as Timestamp,
    );
  }
}

// Modelo para los datos de un pago.
class Pago {
  final String id;
  final String rubro;
  final double monto;
  final Timestamp fechaPago;
  final String metodoPago;
  final String tipo; // 'total' o 'parcial'

  const Pago({
    required this.id,
    required this.rubro,
    required this.monto,
    required this.fechaPago,
    required this.metodoPago,
    required this.tipo,
  });

  factory Pago.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Pago(
      id: doc.id,
      rubro: data['rubro'] as String,
      monto: (data['monto'] as num).toDouble(),
      fechaPago: data['fechaPago'] as Timestamp,
      metodoPago: data['metodoPago'] as String,
      // Si el campo 'tipo' no existe en documentos antiguos, lo tratamos como 'total' para mantener la compatibilidad.
      tipo: data['tipo'] as String? ?? 'total',
    );
  }
}

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
                                );
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

// Nueva pantalla para mostrar los rubros de pago de un alumno.
class PagosScreen extends StatelessWidget {
  final Alumno alumno;

  const PagosScreen({super.key, required this.alumno});

  @override
  Widget build(BuildContext context) {
    // Lista de los rubros de pago.
    final List<String> rubrosDePago = [
      'Inscripción',
      'Material Escolar',
      'Libros',
      'Uniforme',
      'Bata',
      'Colegiatura',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Pagos de ${alumno.nombre}'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('alumnos')
            .doc(alumno.id)
            .collection('pagos')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los pagos.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron pagos.'));
          }

          // 1. Agrupamos todos los pagos por su rubro.
          final Map<String, List<Pago>> pagosPorRubro = {};
          for (var doc in snapshot.data!.docs) {
            final pago = Pago.fromFirestore(doc);
            pagosPorRubro.putIfAbsent(pago.rubro, () => []).add(pago);
          }

          // 2. Determinamos si un rubro está totalmente pagado.
          final Map<String, bool> rubrosTotalmentePagados = {};
          pagosPorRubro.forEach((rubro, pagos) {
            // Un rubro se considera pagado si CUALQUIERA de sus pagos fue de tipo 'total'.
            rubrosTotalmentePagados[rubro] = pagos.any(
              (p) => p.tipo == 'total',
            );
          });

          return ListView.separated(
            itemCount: rubrosDePago.length,
            itemBuilder: (context, index) {
              final rubro = rubrosDePago[index];
              final pagosDeEsteRubro = pagosPorRubro[rubro] ?? [];
              final isTotalmentePagado =
                  rubrosTotalmentePagados[rubro] ?? false;
              final tienePagosParciales =
                  pagosDeEsteRubro.isNotEmpty && !isTotalmentePagado;

              // Determinamos el estado para la UI
              String estadoTexto;
              Color estadoColor;
              IconData estadoIcono;

              if (isTotalmentePagado) {
                estadoTexto = 'Pagado';
                estadoColor = Colors.green;
                estadoIcono = Icons.check_circle;
              } else if (tienePagosParciales) {
                estadoTexto = 'Parcial';
                estadoColor = Colors.blue;
                estadoIcono = Icons.hourglass_top_outlined;
              } else {
                estadoTexto = 'Pendiente';
                estadoColor = Colors.orange;
                estadoIcono = Icons.hourglass_empty;
              }

              return ListTile(
                leading: Icon(estadoIcono, color: estadoColor),
                title: Text(rubro),
                trailing: Text(
                  estadoTexto,
                  style: TextStyle(
                    color: estadoColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  if (isTotalmentePagado) {
                    // Si está totalmente pagado, mostramos el historial.
                    _showPaymentHistoryDialog(context, rubro, pagosDeEsteRubro);
                  } else {
                    // Si está pendiente o con pagos parciales, permitimos agregar otro pago.
                    _showAddPaymentDialog(context, rubro);
                  }
                },
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
          );
        },
      ),
    );
  }

  // Método para mostrar el diálogo de registro de pago.
  Future<void> _showAddPaymentDialog(BuildContext context, String rubro) async {
    final formKey = GlobalKey<FormState>();
    final montoController = TextEditingController();
    final fechaController = TextEditingController();
    DateTime? selectedDate;
    String? selectedMetodo;
    final List<String> metodosDePago = ['Efectivo', 'Tarjeta'];
    bool esPagoTotal = false; // Nuevo estado para el switch

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Registrar Pago: $rubro'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  // Para evitar desbordamiento si aparece el teclado.
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingrese el monto';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor, ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: fechaController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Pago',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                              // Para un formato más amigable, se puede usar el paquete 'intl'.
                              fechaController.text =
                                  "${picked.day}/${picked.month}/${picked.year}";
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, seleccione una fecha';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedMetodo,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Seleccione un método'),
                        items: metodosDePago.map((String metodo) {
                          return DropdownMenuItem<String>(
                            value: metodo,
                            child: Text(metodo),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() => selectedMetodo = newValue);
                        },
                        validator: (value) => value == null
                            ? 'Por favor, seleccione un método'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Switch para marcar si es pago total
                      SwitchListTile(
                        title: const Text('Pago Total'),
                        subtitle: const Text(
                          'Activa esto para liquidar el rubro.',
                        ),
                        value: esPagoTotal,
                        onChanged: (bool value) {
                          setState(() => esPagoTotal = value);
                        },
                        secondary: Icon(
                          esPagoTotal ? Icons.lock : Icons.lock_open,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // 1. Preparamos los datos para Firestore.
                  final pagoData = {
                    'rubro': rubro,
                    'monto': double.parse(montoController.text),
                    'fechaPago': Timestamp.fromDate(selectedDate!),
                    'metodoPago': selectedMetodo,
                    'tipo': esPagoTotal ? 'total' : 'parcial',
                  };

                  try {
                    // 2. Guardamos el nuevo documento en la subcolección 'pagos' del alumno.
                    await FirebaseFirestore.instance
                        .collection('alumnos')
                        .doc(alumno.id)
                        .collection('pagos')
                        .add(pagoData);

                    Navigator.of(dialogContext).pop(); // Cerramos el diálogo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pago guardado correctamente.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar el pago: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Nuevo método para mostrar el historial de pagos de un rubro.
  void _showPaymentHistoryDialog(
    BuildContext context,
    String rubro,
    List<Pago> pagos,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Historial de Pagos: $rubro'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: pagos.length,
              itemBuilder: (context, index) {
                final pago = pagos[index];
                final fecha = pago.fechaPago.toDate();
                final fechaFormateada =
                    "${fecha.day}/${fecha.month}/${fecha.year}";
                return ListTile(
                  title: Text(
                    '\$${pago.monto.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$fechaFormateada - ${pago.metodoPago}'),
                  trailing: pago.tipo == 'total'
                      ? Chip(
                          label: const Text(
                            'Total',
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.green[100],
                          padding: EdgeInsets.zero,
                        )
                      : null,
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo de historial
              },
            ),
          ],
        );
      },
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
