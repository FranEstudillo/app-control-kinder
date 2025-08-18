// Importa los paquetes necesarios de Flutter y Firebase.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatear fechas.
import '../models/alumno.dart'; // Modelo de datos para Alumno.
import '../models/pago.dart'; // Modelo de datos para Pago.
import 'package:app_control_kinder_v4/utils/color_utils.dart'; // Utilidades de color.

// Define el widget de la pantalla de Colegiaturas, que es un StatefulWidget.
class ColegiaturasScreen extends StatefulWidget {
  const ColegiaturasScreen({super.key});

  @override
  State<ColegiaturasScreen> createState() => _ColegiaturasScreenState();
}

// Define el estado para ColegiaturasScreen.
class _ColegiaturasScreenState extends State<ColegiaturasScreen> {
  // --- VARIABLES PARA EL FILTRO ---
  String? _filtroGrado;
  final List<String> _grados = ['Maternal', 'Kínder 1', 'Kínder 2', 'Kínder 3'];

  // ✅ 1. DECLARAMOS LA VARIABLE PARA GUARDAR EL FUTURE.
  late Future<Map<String, dynamic>> _datosColegiaturasFuture;

  // ✅ 2. AÑADIMOS EL MÉTODO initState PARA INICIALIZAR LA VARIABLE UNA SOLA VEZ.
  @override
  void initState() {
    super.initState();
    _datosColegiaturasFuture = _getDatosColegiaturas();
  }

  // Muestra un popup para registrar un nuevo pago de colegiatura.
  Future<bool?> _mostrarPopupRegistrarPago() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                                fechaController.text = DateFormat(
                                  'dd/MM/yyyy',
                                ).format(pickedDate);
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
                ),
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
                              if (mounted) {
                                navigator.pop(true);
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Pago guardado.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error al guardar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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

  void _showColegiaturasDetalleDialog(
    BuildContext context,
    Alumno alumno,
    List<Pago> pagos,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Historial de Colegiaturas\n${alumno.nombre}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 11,
              itemBuilder: (context, index) {
                final numeroDePago = index + 1;
                Pago? pagoCorrespondiente;

                if (index < pagos.length) {
                  pagoCorrespondiente = pagos[index];
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: pagoCorrespondiente != null
                        ? Colors.green
                        : Colors.grey[300],
                    foregroundColor: pagoCorrespondiente != null
                        ? Colors.white
                        : Colors.grey[600],
                    child: Text('$numeroDePago'),
                  ),
                  title: Text('Colegiatura $numeroDePago'),
                  subtitle: pagoCorrespondiente != null
                      ? Text(
                          'Pagado el ${DateFormat('dd/MM/yyyy').format(pagoCorrespondiente.fechaPago.toDate())} (${pagoCorrespondiente.metodoPago})',
                          style: const TextStyle(fontSize: 12),
                        )
                      : const Text(
                          'Pendiente',
                          style: TextStyle(color: Colors.orange),
                        ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> queryAlumnos = FirebaseFirestore.instance
        .collection('alumnos')
        .orderBy('nombre');

    if (_filtroGrado != null) {
      queryAlumnos = queryAlumnos.where('grado', isEqualTo: _filtroGrado);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Colegiaturas'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            // ✅ 3. USA LA VARIABLE DEL ESTADO EN LUGAR DE LLAMAR A LA FUNCIÓN DIRECTAMENTE.
            future: _datosColegiaturasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error al cargar los datos'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay datos disponibles'));
              }

              final datos = snapshot.data!;
              final totalGeneral = datos['totalGeneral'] as double;
              final totalEfectivo = datos['totalEfectivo'] as double;
              final totalTarjeta = datos['totalTarjeta'] as double;

              return Padding(
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
                      color: Colors.indigo[50],
                      child: ListTile(
                        leading: const Icon(
                          Icons.credit_card,
                          color: Colors.indigo,
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
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroGrado,
                    hint: const Text('Filtrar alumnos por grado'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: _grados
                        .map(
                          (grado) => DropdownMenuItem(
                            value: grado,
                            child: Text(grado),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() => _filtroGrado = newValue);
                    },
                  ),
                ),
                if (_filtroGrado != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Limpiar filtro',
                    onPressed: () {
                      setState(() => _filtroGrado = null);
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: queryAlumnos.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay alumnos que coincidan con el filtro.'),
                  );
                }

                final alumnos = snapshot.data!.docs
                    .map((doc) => Alumno.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: alumnos.length,
                  itemBuilder: (context, index) {
                    final alumno = alumnos[index];
                    var colorGrado = getColorForGrado(alumno.grado);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(
                          color: getColorForGrado(alumno.grado),
                          width: 1.2,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorGrado.withOpacity(0.2),
                          child: Text(
                            alumno.nombre.substring(0, 1),
                            style: TextStyle(color: colorGrado),
                          ),
                        ),
                        title: Text(alumno.nombre),
                        subtitle: Text(alumno.grado),
                        trailing:
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('alumnos')
                                  .doc(alumno.id)
                                  .collection('pagos')
                                  .where('rubro', isEqualTo: 'Colegiatura')
                                  .orderBy('fechaPago', descending: false)
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

                                final pagos =
                                    pagoSnapshot.data?.docs
                                        .map((doc) => Pago.fromFirestore(doc))
                                        .toList() ??
                                    [];
                                final pagosContados = pagos.length;

                                return InkWell(
                                  onTap: () {
                                    _showColegiaturasDetalleDialog(
                                      context,
                                      alumno,
                                      pagos,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Chip(
                                    label: Text('Pagos: $pagosContados / 11'),
                                    backgroundColor: pagosContados >= 11
                                        ? Colors.green[100]
                                        : Colors.amber[100],
                                  ),
                                );
                              },
                            ),
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
        onPressed: () async {
          final huboCambios = await _mostrarPopupRegistrarPago();
          if (huboCambios == true) {
            setState(() {
              // ✅ 4. VUELVE A EJECUTAR LA CONSULTA SOLO CUANDO HAYA CAMBIOS.
              _datosColegiaturasFuture = _getDatosColegiaturas();
            });
          }
        },
        tooltip: 'Registrar Pago de Colegiatura',
        backgroundColor: Colors.blue.shade900,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
