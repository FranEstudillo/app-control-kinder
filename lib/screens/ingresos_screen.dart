// import 'package:app_control_kinder_v4/models/alumno.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pago.dart';
import '../models/gasto.dart';
import '../models/movimiento.dart'; // Asegúrate que este import esté

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  String? _gradoSeleccionado;
  final List<String> _grados = ['Maternal', 'Kínder 1', 'Kínder 2', 'Kínder 3'];
  final List<String> _rubros = [
    'Inscripción',
    'Material Escolar',
    'Libros',
    'Uniforme',
    'Bata',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _seleccionarGrado(context),
    );
  }

  Future<void> _seleccionarGrado(BuildContext context) async {
    final grado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un grado'),
        content: DropdownButtonFormField<String>(
          value: _gradoSeleccionado,
          items: _grados
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              Navigator.of(context).pop(value);
            }
          },
          decoration: const InputDecoration(labelText: 'Grado'),
        ),
      ),
    );
    if (grado != null) {
      setState(() => _gradoSeleccionado = grado);
    }
  }

  // --- FUNCIÓN DE POPUP PARA REGISTRAR GASTO (ACTUALIZADA) ---
  // En la clase _IngresosScreenState
  // En la clase _IngresosScreenState
  void _mostrarPopupRegistrarGasto(BuildContext context, String rubro) {
    final montoController = TextEditingController();
    String fuenteSeleccionada = 'Efectivo';

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Registrar Gasto en "$rubro"'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto del Gasto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Efectivo'),
                      Radio<String>(
                        value: 'Efectivo',
                        groupValue: fuenteSeleccionada,
                        onChanged: (v) =>
                            setDialogState(() => fuenteSeleccionada = v!),
                      ),
                      const Text('Tarjeta'),
                      Radio<String>(
                        value: 'Tarjeta',
                        groupValue: fuenteSeleccionada,
                        onChanged: (v) =>
                            setDialogState(() => fuenteSeleccionada = v!),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => navigator.pop(),
                ),
                ElevatedButton(
                  child: const Text('Guardar Gasto'),
                  onPressed: () async {
                    final monto = double.tryParse(montoController.text);
                    if (monto == null || monto <= 0) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, ingrese un monto válido.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      // --- ✅ VALIDACIÓN DE FONDOS RESTAURADA ---
                      double ingresosFuente = 0;
                      final alumnosSnapshot = await FirebaseFirestore.instance
                          .collection('alumnos')
                          .where('grado', isEqualTo: _gradoSeleccionado!)
                          .get();
                      for (final alumnoDoc in alumnosSnapshot.docs) {
                        final pagosSnapshot = await alumnoDoc.reference
                            .collection('pagos')
                            .where('rubro', isEqualTo: rubro)
                            .where('metodoPago', isEqualTo: fuenteSeleccionada)
                            .get();
                        ingresosFuente += pagosSnapshot.docs.fold(
                          0.0,
                          (sum, doc) => sum + (doc.data()['monto'] as num),
                        );
                      }

                      double gastosFuente = 0;
                      final gastosSnapshot = await FirebaseFirestore.instance
                          .collection('gastos')
                          .where('grado', isEqualTo: _gradoSeleccionado!)
                          .where('rubro', isEqualTo: rubro)
                          .where('fuente', isEqualTo: fuenteSeleccionada)
                          .get();
                      gastosFuente += gastosSnapshot.docs.fold(
                        0.0,
                        (sum, doc) => sum + (doc.data()['monto'] as num),
                      );

                      final saldoActual = ingresosFuente - gastosFuente;
                      if (monto > saldoActual) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'No hay fondos suficientes. Saldo: \$${saldoActual.toStringAsFixed(2)}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      // --- FIN DE LA VALIDACIÓN ---

                      final nuevoGasto = Gasto(
                        monto: monto,
                        fuente: fuenteSeleccionada,
                        rubro: rubro,
                        grado: _gradoSeleccionado!,
                        fecha: Timestamp.now(),
                      );
                      await FirebaseFirestore.instance
                          .collection('gastos')
                          .add(nuevoGasto.toJson());

                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Gasto registrado.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      setState(() {});
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FUNCIÓN DE POPUP PARA EDITAR GASTO (ACTUALIZADA) ---
  // En la clase _IngresosScreenState
  // En la clase _IngresosScreenState
  void _mostrarPopupEditarGasto(
    BuildContext context,
    Movimiento gastoParaEditar,
  ) {
    final montoController = TextEditingController(
      text: gastoParaEditar.monto.toString(),
    );
    String fuenteSeleccionada = gastoParaEditar.fuente;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Gasto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Efectivo'),
                      Radio<String>(
                        value: 'Efectivo',
                        groupValue: fuenteSeleccionada,
                        onChanged: (v) =>
                            setDialogState(() => fuenteSeleccionada = v!),
                      ),
                      const Text('Tarjeta'),
                      Radio<String>(
                        value: 'Tarjeta',
                        groupValue: fuenteSeleccionada,
                        onChanged: (v) =>
                            setDialogState(() => fuenteSeleccionada = v!),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => navigator.pop(),
                ),
                ElevatedButton(
                  child: const Text('Guardar Cambios'),
                  onPressed: () async {
                    final montoEditado = double.tryParse(montoController.text);
                    if (montoEditado == null || montoEditado <= 0) return;

                    try {
                      // --- ✅ VALIDACIÓN DE FONDOS PARA EDICIÓN ---
                      // La lógica es la misma, pero al calcular el saldo, "devolvemos" temporalmente
                      // el monto original del gasto que estamos editando.
                      double ingresosFuente = 0;
                      final alumnosSnapshot = await FirebaseFirestore.instance
                          .collection('alumnos')
                          .where('grado', isEqualTo: _gradoSeleccionado!)
                          .get();
                      for (final alumnoDoc in alumnosSnapshot.docs) {
                        final pagosSnapshot = await alumnoDoc.reference
                            .collection('pagos')
                            .where('rubro', isEqualTo: gastoParaEditar.rubro)
                            .where('metodoPago', isEqualTo: fuenteSeleccionada)
                            .get();
                        ingresosFuente += pagosSnapshot.docs.fold(
                          0.0,
                          (sum, doc) => sum + (doc.data()['monto'] as num),
                        );
                      }

                      double gastosFuente = 0;
                      final gastosSnapshot = await FirebaseFirestore.instance
                          .collection('gastos')
                          .where('grado', isEqualTo: _gradoSeleccionado!)
                          .where('rubro', isEqualTo: gastoParaEditar.rubro)
                          .where('fuente', isEqualTo: fuenteSeleccionada)
                          .get();
                      gastosFuente += gastosSnapshot.docs.fold(
                        0.0,
                        (sum, doc) => sum + (doc.data()['monto'] as num),
                      );

                      // Saldo disponible sin contar el gasto que editamos
                      final saldoDisponible =
                          ingresosFuente -
                          (gastosFuente - gastoParaEditar.monto);

                      if (montoEditado > saldoDisponible) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'No hay fondos suficientes. Saldo disponible: \$${saldoDisponible.toStringAsFixed(2)}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      // --- FIN DE LA VALIDACIÓN ---

                      await FirebaseFirestore.instance
                          .collection('gastos')
                          .doc(gastoParaEditar.id)
                          .update({
                            'monto': montoEditado,
                            'fuente': fuenteSeleccionada,
                          });

                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Gasto actualizado.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      setState(() {});
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
    if (_gradoSeleccionado == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: _rubros.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ingresos - $_gradoSeleccionado'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: () => _seleccionarGrado(context),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: _rubros.map((rubro) => Tab(text: rubro)).toList(),
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: _rubros.map((rubro) {
            return _PagosPorRubro(
              grado: _gradoSeleccionado!,
              rubro: rubro,
              // Le pasamos la función de editar al widget hijo
              onEditGasto: (movimiento) =>
                  _mostrarPopupEditarGasto(context, movimiento),
            );
          }).toList(),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final tabController = DefaultTabController.of(context);
                final rubroSeleccionado = _rubros[tabController.index];
                _mostrarPopupRegistrarGasto(context, rubroSeleccionado);
              },
              tooltip: 'Registrar Gasto',
              backgroundColor: Colors.red,
              child: const Icon(Icons.add, color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}

// --- WIDGET _PagosPorRubro (ACTUALIZADO) ---
class _PagosPorRubro extends StatelessWidget {
  final String grado;
  final String rubro;
  final Function(Movimiento) onEditGasto; // Función para manejar la edición

  const _PagosPorRubro({
    required this.grado,
    required this.rubro,
    required this.onEditGasto,
  });

  Future<Map<String, dynamic>> _getMovimientos() async {
    final List<Movimiento> movimientos = [];
    double totalIngresos = 0, ingresosEfectivo = 0, ingresosTarjeta = 0;
    double totalGastos = 0, gastosEfectivo = 0, gastosTarjeta = 0;

    final alumnosSnapshot = await FirebaseFirestore.instance
        .collection('alumnos')
        .where('grado', isEqualTo: grado)
        .get();
    for (final alumnoDoc in alumnosSnapshot.docs) {
      final pagosSnapshot = await alumnoDoc.reference
          .collection('pagos')
          .where('rubro', isEqualTo: rubro)
          .get();
      for (final pagoDoc in pagosSnapshot.docs) {
        final alumnoNombre =
            alumnoDoc.data()['nombre']
                as String; // Obtiene el nombre del alumno
        final pago = Pago.fromFirestore(pagoDoc);
        // ✅ AÑADE 'rubro: pago.rubro'
        movimientos.add(
          Movimiento(
            id: pago.id,
            monto: pago.monto,
            fecha: pago.fechaPago,
            fuente: pago.metodoPago,
            tipo: 'ingreso',
            rubro: pago.rubro,
            nombreAlumno: alumnoNombre, // ✅ Añade el nombre del alumno
          ),
        );
        totalIngresos += pago.monto;
        if (pago.metodoPago == 'Efectivo') {
          ingresosEfectivo += pago.monto;
        } else if (pago.metodoPago == 'Tarjeta')
          ingresosTarjeta += pago.monto;
      }
    }

    final gastosSnapshot = await FirebaseFirestore.instance
        .collection('gastos')
        .where('grado', isEqualTo: grado)
        .where('rubro', isEqualTo: rubro)
        .get();
    for (var doc in gastosSnapshot.docs) {
      final gasto = doc.data();
      final montoGasto = (gasto['monto'] as num).toDouble();
      // ✅ AÑADE 'rubro: gasto['rubro']'
      movimientos.add(
        Movimiento(
          id: doc.id,
          monto: montoGasto,
          fecha: gasto['fecha'],
          fuente: gasto['fuente'],
          tipo: 'gasto',
          rubro: gasto['rubro'],
          nombreAlumno: '', // ✅ No hay alumno para los gastos
        ),
      );
      totalGastos += montoGasto;
      if (gasto['fuente'] == 'Efectivo') {
        gastosEfectivo += montoGasto;
      } else if (gasto['fuente'] == 'Tarjeta')
        gastosTarjeta += montoGasto;
    }

    movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));

    return {
      'movimientos': movimientos,
      'totalNeto': totalIngresos - totalGastos,
      'totalEfectivo': ingresosEfectivo - gastosEfectivo,
      'totalTarjeta': ingresosTarjeta - gastosTarjeta,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getMovimientos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {};
        final movimientos = data['movimientos'] as List<Movimiento>? ?? [];
        final totalNeto = data['totalNeto'] as double? ?? 0.0;
        final totalEfectivo = data['totalEfectivo'] as double? ?? 0.0;
        final totalTarjeta = data['totalTarjeta'] as double? ?? 0.0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green,
                  ),
                  title: Text('Total neto en "$rubro"'),
                  trailing: Text(
                    '\$${totalNeto.toStringAsFixed(2)}',
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
                  leading: const Icon(Icons.payments, color: Colors.orange),
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
                color: Colors.blue[50],
                child: ListTile(
                  leading: const Icon(Icons.credit_card, color: Colors.blue),
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
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Historial de Movimientos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (movimientos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No hay movimientos.'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: movimientos.length,
                  itemBuilder: (context, index) {
                    final movimiento = movimientos[index];
                    final esIngreso = movimiento.tipo == 'ingreso';
                    final fecha = movimiento.fecha.toDate();
                    final fechaFormateada =
                        "${fecha.day}/${fecha.month}/${fecha.year}";
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                          color: esIngreso ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          '\$${movimiento.monto.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: esIngreso ? Colors.green : Colors.red,
                          ),
                        ),
                        subtitle: Text(
                          '$fechaFormateada - ${movimiento.fuente} - ${movimiento.nombreAlumno}',
                        ),
                        trailing: esIngreso
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () => onEditGasto(
                                  movimiento,
                                ), // ¡Llamada correcta!
                              ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
