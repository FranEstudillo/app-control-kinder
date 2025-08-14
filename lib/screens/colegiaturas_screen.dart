// Importa los paquetes necesarios de Flutter y Firebase.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatear fechas.
import '../models/alumno.dart'; // Modelo de datos para Alumno.
import '../models/pago.dart'; // Modelo de datos para Pago.

// Define el widget de la pantalla de Colegiaturas, que es un StatefulWidget.
class ColegiaturasScreen extends StatefulWidget {
  const ColegiaturasScreen({super.key});

  @override
  State<ColegiaturasScreen> createState() => _ColegiaturasScreenState();
}

// Define el estado para ColegiaturasScreen.
class _ColegiaturasScreenState extends State<ColegiaturasScreen> {
  /*** 
  // Muestra un diálogo con el historial de pagos de colegiatura de un alumno específico.
  Future<void> _mostrarHistorialPagos(
    String alumnoId,
    String alumnoNombre,
  ) async {
    // 1. Obtiene el historial de pagos de la colección 'pagos' del alumno.
    final pagosSnapshot = await FirebaseFirestore.instance
        .collection('alumnos')
        .doc(alumnoId)
        .collection('pagos')
        .where(
          'rubro',
          isEqualTo: 'Colegiatura',
        ) // Filtra solo por colegiaturas.
        .orderBy('fechaPago', descending: true) // Ordena los pagos por fecha.
        .get();

    // 2. Convierte los documentos de Firestore a una lista de objetos Pago.
    final pagos = pagosSnapshot.docs
        .map((doc) => Pago.fromFirestore(doc))
        .toList();

    // 3. Comprueba si el widget todavía está montado antes de mostrar el diálogo para evitar errores.
    if (!mounted) return;

    // 4. Muestra el diálogo con la lista de pagos.
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial de Pagos de $alumnoNombre'),
        content: SizedBox(
          width: double.maxFinite,
          child: pagos.isEmpty
              ? const Text('No hay pagos registrados para este rubro.')
              : ListView.builder(
                  // Muestra los pagos en una lista.
                  shrinkWrap: true,
                  itemCount: pagos.length,
                  itemBuilder: (context, index) {
                    final pago = pagos[index];
                    // Formatea la fecha del pago para mostrarla en formato dd/MM/yyyy.
                    final fechaFormateada = DateFormat(
                      'dd/MM/yyyy',
                    ).format(pago.fechaPago.toDate());
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(
                        'Monto: \${pago.monto.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Fecha: $fechaFormateada\nMétodo: ${pago.metodoPago}',
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
      ),
    );
  }

  
  */
  // Muestra un popup para registrar un nuevo pago de colegiatura.
  Future<bool?> _mostrarPopupRegistrarPago() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // El usuario no puede cerrar el diálogo tocando fuera de él.
      builder: (BuildContext context) {
        // Clave para el formulario.
        final formKey = GlobalKey<FormState>();
        // Listas para los menús desplegables.
        final List<String> grados = [
          'Maternal',
          'Kínder 1',
          'Kínder 2',
          'Kínder 3',
        ];
        final List<String> metodosDePago = ['Efectivo', 'Tarjeta'];
        // Variables para almacenar los datos del formulario.
        String? gradoSeleccionado;
        Alumno? alumnoSeleccionado;
        List<Alumno> alumnosDelGrado = [];
        bool cargandoAlumnos = false;
        final montoController = TextEditingController();
        final fechaController = TextEditingController();
        DateTime? fechaSeleccionada;
        String? metodoSeleccionado;

        // Referencias para Navigator y ScaffoldMessenger para usarlas de forma segura en contextos asíncronos.
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        // Usa StatefulBuilder para manejar el estado dentro del diálogo.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Carga los alumnos de un grado específico desde Firestore.
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
                  // Permite hacer scroll si el contenido es muy largo.
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Menú desplegable para seleccionar el grado.
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
                            cargarAlumnos(
                              newValue,
                            ); // Carga los alumnos del grado seleccionado.
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Seleccione un grado' : null,
                      ),
                      const SizedBox(height: 16),
                      // Muestra un indicador de carga mientras se obtienen los alumnos.
                      if (cargandoAlumnos)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        )
                      // Menú desplegable para seleccionar el alumno.
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
                      // Campos de texto y menús que aparecen cuando se selecciona un alumno.
                      if (alumnoSeleccionado != null) ...[
                        // Campo para ingresar el monto.
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
                        // Campo para seleccionar la fecha de pago.
                        TextFormField(
                          controller: fechaController,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Pago',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          readOnly:
                              true, // El campo no es editable directamente.
                          onTap: () async {
                            // Muestra un selector de fecha al tocar.
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
                        // Menú desplegable para seleccionar el método de pago.
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
                // Botón para cancelar el registro.
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () =>
                      navigator.pop(false), // Cierra el popup y devuelve false.
                ),
                // Botón para guardar el pago.
                ElevatedButton(
                  onPressed: alumnoSeleccionado == null
                      ? null // El botón está deshabilitado si no se ha seleccionado un alumno.
                      : () async {
                          // Valida el formulario antes de guardar.
                          if (formKey.currentState!.validate()) {
                            // Crea un mapa con los datos del pago.
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
                              // Guarda el pago en la subcolección 'pagos' del alumno.
                              await FirebaseFirestore.instance
                                  .collection('alumnos')
                                  .doc(alumnoSeleccionado!.id)
                                  .collection('pagos')
                                  .add(pagoData);
                              if (mounted) {
                                navigator.pop(
                                  true,
                                ); // Cierra el popup y devuelve true.
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Pago guardado.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              // Muestra un mensaje de error si falla el guardado.
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

  // Obtiene los datos de las colegiaturas desde Firestore.
  Future<Map<String, dynamic>> _getDatosColegiaturas() async {
    // Obtiene todos los alumnos.
    final alumnosSnapshot = await FirebaseFirestore.instance
        .collection('alumnos')
        .orderBy('nombre')
        .get();
    final alumnos = alumnosSnapshot.docs
        .map((doc) => Alumno.fromFirestore(doc))
        .toList();

    // Inicializa los totales.
    double totalGeneral = 0;
    double totalEfectivo = 0;
    double totalTarjeta = 0;

    // Obtiene todos los pagos de colegiatura de todos los alumnos.
    final pagosSnapshot = await FirebaseFirestore.instance
        .collectionGroup(
          'pagos',
        ) // Busca en la subcolección 'pagos' de todos los documentos.
        .where('rubro', isEqualTo: 'Colegiatura')
        .get();
    // Calcula los totales.
    for (final pagoDoc in pagosSnapshot.docs) {
      final pago = Pago.fromFirestore(pagoDoc);
      totalGeneral += pago.monto;
      if (pago.metodoPago == 'Efectivo') {
        totalEfectivo += pago.monto;
      } else if (pago.metodoPago == 'Tarjeta') {
        totalTarjeta += pago.monto;
      }
    }

    // Devuelve un mapa con los datos.
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
      // FutureBuilder para construir la UI basada en los datos asíncronos.
      body: FutureBuilder<Map<String, dynamic>>(
        future:
            _getDatosColegiaturas(), // Llama a la función que obtiene los datos.
        builder: (context, snapshot) {
          // Muestra un indicador de carga mientras se esperan los datos.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Muestra un mensaje de error si ocurre un problema.
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar los datos: ${snapshot.error}'),
            );
          }
          // Muestra un mensaje si no hay datos.
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay datos disponibles.'));
          }

          // Extrae los datos del snapshot.
          final datos = snapshot.data!;
          final alumnos = datos['alumnos'] as List<Alumno>;
          final totalGeneral = datos['totalGeneral'] as double;
          final totalEfectivo = datos['totalEfectivo'] as double;
          final totalTarjeta = datos['totalTarjeta'] as double;

          // Construye la UI principal.
          return Column(
            children: [
              // Sección de tarjetas con los totales.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Tarjeta para el total recaudado.
                    Card(
                      color: Colors.blue[50],
                      child: ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.blue,
                        ),
                        title: const Text('Total Recaudado (Colegiaturas)'),
                        trailing: Text(
                          totalGeneral.toStringAsFixed(2),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Tarjeta para el total en efectivo.
                    Card(
                      color: Colors.orange[50],
                      child: ListTile(
                        leading: const Icon(
                          Icons.payments,
                          color: Colors.orange,
                        ),
                        title: const Text('Total en efectivo'),
                        trailing: Text(
                          totalEfectivo.toStringAsFixed(2),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Tarjeta para el total en tarjeta.
                    Card(
                      color: Colors.blueGrey[50],
                      child: ListTile(
                        leading: const Icon(
                          Icons.credit_card,
                          color: Colors.blueGrey,
                        ),
                        title: const Text('Total en tarjeta'),
                        trailing: Text(
                          totalTarjeta.toStringAsFixed(2),
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
              const Divider(thickness: 1), // Separador visual.
              // Lista de alumnos.
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
                        // StreamBuilder para mostrar el número de pagos en tiempo real.-m
                        trailing: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('alumnos')
                              .doc(alumno.id)
                              .collection('pagos')
                              .where('rubro', isEqualTo: 'Colegiatura')
                              .snapshots(), // Escucha los cambios en los pagos.
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
                            // Chip que muestra el conteo de pagos y abre el historial al tocarlo.
                            return GestureDetector(
                              // onTap: () {
                              //   final alumnoId = alumno.id;
                              //   final alumnoNombre = alumno.nombre;
                              //   if (alumnoId != null && alumnoNombre != null) {
                              //     _mostrarHistorialPagos(
                              //       alumnoId,
                              //       alumnoNombre,
                              //     );
                              //   }
                              // },
                              child: Chip(
                                label: Text('Pagos: $pagosContados / 11'),
                                backgroundColor: pagosContados >= 11
                                    ? Colors
                                          .green[100] // Verde si está completo.
                                    : Colors
                                          .amber[100], // Ámbar si está incompleto.
                              ),
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
      // Botón flotante para registrar un nuevo pago.
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Muestra el popup y actualiza el estado si se realizó un cambio.
          final huboCambios = await _mostrarPopupRegistrarPago();
          if (huboCambios == true) {
            setState(
              () {},
            ); // Vuelve a construir el widget para reflejar los cambios.
          }
        },
        tooltip: 'Registrar Pago de Colegiatura',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
