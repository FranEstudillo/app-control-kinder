import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alumno.dart';
import '../models/pago.dart';

class ColegiaturasScreen extends StatefulWidget {
  const ColegiaturasScreen({super.key});

  @override
  State<ColegiaturasScreen> createState() => _ColegiaturasScreenState();
}

class _ColegiaturasScreenState extends State<ColegiaturasScreen> {
  // Función que muestra el popup y devuelve 'true' si se guarda un pago
  Future<bool?> _mostrarPopupRegistrarPago() async {
    // Usamos showDialog<bool> para indicar que devolverá un valor booleano
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Evita que se cierre al tocar fuera
      builder: (BuildContext context) {
        // Todas las variables y controladores para el estado del popup
        final formKey = GlobalKey<FormState>();
        final List<String> grados = [
          'Maternal',
          'Kínder 1',
          'Kínder 2',
          'Kínder 3',
        ];
        final List<String> metodosDePago = ['Efectivo', 'Tarjeta'];
        String? gradoSeleccionado;
        Alumno? alumnoSeleccionado;
        List<Alumno> alumnosDelGrado = [];
        bool cargandoAlumnos = false;
        final montoController = TextEditingController();
        final fechaController = TextEditingController();
        DateTime? fechaSeleccionada;
        String? metodoSeleccionado;

        // Guardamos las referencias del context principal para usarlas de forma segura
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> cargarAlumnos(String grado) async {
              setDialogState(() {
                cargandoAlumnos = true;
                alumnosDelGrado = [];
                alumnoSeleccionado = null;
              });
              final querySnapshot = await FirebaseFirestore.instance
                  .collection('alumnos')
                  .where('grado', isEqualTo: grado)
                  .get();
              final alumnos = querySnapshot.docs
                  .map((doc) => Alumno.fromFirestore(doc))
                  .toList();
              setDialogState(() {
                alumnosDelGrado = alumnos;
                cargandoAlumnos = false;
              });
            }

            return AlertDialog(
              title: const Text('Registrar Pago de Colegiatura'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: gradoSeleccionado,
                        hint: const Text('Seleccione un grado'),
                        decoration: const InputDecoration(
                          labelText: 'Grado',
                          border: OutlineInputBorder(),
                        ),
                        items: grados
                            .map(
                              (g) => DropdownMenuItem<String>(
                                value: g,
                                child: Text(g),
                              ),
                            )
                            .toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() => gradoSeleccionado = newValue);
                            cargarAlumnos(newValue);
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Seleccione un grado' : null,
                      ),
                      const SizedBox(height: 16),
                      if (cargandoAlumnos)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        )
                      else if (gradoSeleccionado != null)
                        DropdownButtonFormField<Alumno>(
                          value: alumnoSeleccionado,
                          hint: const Text('Seleccione un alumno'),
                          decoration: const InputDecoration(
                            labelText: 'Alumno',
                            border: OutlineInputBorder(),
                          ),
                          items: alumnosDelGrado.isEmpty
                              ? [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('No hay alumnos'),
                                  ),
                                ]
                              : alumnosDelGrado
                                    .map(
                                      (a) => DropdownMenuItem<Alumno>(
                                        value: a,
                                        child: Text(a.nombre),
                                      ),
                                    )
                                    .toList(),
                          onChanged: (newValue) => setDialogState(
                            () => alumnoSeleccionado = newValue,
                          ),
                          validator: (value) =>
                              value == null ? 'Seleccione un alumno' : null,
                        ),
                      const SizedBox(height: 16),
                      if (alumnoSeleccionado != null) ...[
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
                            if (value == null ||
                                value.isEmpty ||
                                double.tryParse(value) == null) {
                              return 'Ingrese un monto válido';
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
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                fechaSeleccionada = pickedDate;
                                fechaController.text =
                                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                              });
                            }
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Seleccione una fecha'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: metodoSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Método de Pago',
                            prefixIcon: Icon(Icons.credit_card),
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Seleccione un método'),
                          items: metodosDePago
                              .map(
                                (m) => DropdownMenuItem<String>(
                                  value: m,
                                  child: Text(m),
                                ),
                              )
                              .toList(),
                          onChanged: (newValue) => setDialogState(
                            () => metodoSeleccionado = newValue,
                          ),
                          validator: (value) =>
                              value == null ? 'Seleccione un método' : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => navigator.pop(false),
                ), // Devuelve 'false'
                ElevatedButton(
                  onPressed: alumnoSeleccionado == null
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final pagoData = {
                              'rubro': 'Colegiatura',
                              'monto': double.parse(montoController.text),
                              'fechaPago': Timestamp.fromDate(
                                fechaSeleccionada!,
                              ),
                              'metodoPago': metodoSeleccionado,
                              'tipo': 'total',
                            };
                            try {
                              await FirebaseFirestore.instance
                                  .collection('alumnos')
                                  .doc(alumnoSeleccionado!.id)
                                  .collection('pagos')
                                  .add(pagoData);
                              navigator.pop(true); // Devuelve 'true' al guardar
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Pago guardado.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error al guardar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Guardar Pago'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getDatosColegiaturas() async {
    final alumnosSnapshot = await FirebaseFirestore.instance
        .collection('alumnos')
        .orderBy('nombre')
        .get();
    final alumnos = alumnosSnapshot.docs
        .map((doc) => Alumno.fromFirestore(doc))
        .toList();

    double totalGeneral = 0;
    double totalEfectivo = 0;
    double totalTarjeta = 0;

    final pagosSnapshot = await FirebaseFirestore.instance
        .collectionGroup('pagos')
        .where('rubro', isEqualTo: 'Colegiatura')
        .get();
    for (final pagoDoc in pagosSnapshot.docs) {
      final pago = Pago.fromFirestore(pagoDoc);
      totalGeneral += pago.monto;
      if (pago.metodoPago == 'Efectivo') {
        totalEfectivo += pago.monto;
      } else if (pago.metodoPago == 'Tarjeta') {
        totalTarjeta += pago.monto;
      }
    }

    return {
      'alumnos': alumnos,
      'totalGeneral': totalGeneral,
      'totalEfectivo': totalEfectivo,
      'totalTarjeta': totalTarjeta,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Colegiaturas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getDatosColegiaturas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar los datos: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay datos disponibles.'));
          }

          final datos = snapshot.data!;
          final alumnos = datos['alumnos'] as List<Alumno>;
          final totalGeneral = datos['totalGeneral'] as double;
          final totalEfectivo = datos['totalEfectivo'] as double;
          final totalTarjeta = datos['totalTarjeta'] as double;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Card(
                      color: Colors.blue[50],
                      child: ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.blue,
                        ),
                        title: const Text('Total Recaudado (Colegiaturas)'),
                        trailing: Text(
                          '\$${totalGeneral.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    Card(
                      color: Colors.orange[50],
                      child: ListTile(
                        leading: const Icon(
                          Icons.payments,
                          color: Colors.orange,
                        ),
                        title: const Text('Total en efectivo'),
                        trailing: Text(
                          '\$${totalEfectivo.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    Card(
                      color: Colors.blueGrey[50],
                      child: ListTile(
                        leading: const Icon(
                          Icons.credit_card,
                          color: Colors.blueGrey,
                        ),
                        title: const Text('Total en tarjeta'),
                        trailing: Text(
                          '\$${totalTarjeta.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: alumnos.length,
                  itemBuilder: (context, index) {
                    final alumno = alumnos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(alumno.nombre.substring(0, 1)),
                        ),
                        title: Text(alumno.nombre),
                        subtitle: Text(alumno.grado),
                        trailing: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('alumnos')
                              .doc(alumno.id)
                              .collection('pagos')
                              .where('rubro', isEqualTo: 'Colegiatura')
                              .snapshots(),
                          builder: (context, pagoSnapshot) {
                            if (pagoSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            final pagosContados =
                                pagoSnapshot.data?.docs.length ?? 0;
                            return Chip(
                              label: Text('Pagos: $pagosContados / 11'),
                              backgroundColor: pagosContados >= 11
                                  ? Colors.green[100]
                                  : Colors.amber[100],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final huboCambios = await _mostrarPopupRegistrarPago();
          if (huboCambios == true) {
            setState(() {});
          }
        },
        tooltip: 'Registrar Pago de Colegiatura',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
