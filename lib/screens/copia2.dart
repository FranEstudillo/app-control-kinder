import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alumno.dart';
import '../models/pago.dart';

class PagosScreen extends StatefulWidget {
  final Alumno alumno;
  const PagosScreen({super.key, required this.alumno});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  late Alumno alumnoActual;

  @override
  void initState() {
    super.initState();
    alumnoActual = widget.alumno;
  }

  final List<String> rubrosDePago = [
    'Inscripción',
    'Material Escolar',
    'Libros',
    'Uniforme',
    'Bata',
  ];

  // --- FUNCIÓN PARA ASIGNAR/EDITAR PIEZAS DE UNIFORME ---
  Future<void> _showAssignUniformeDialog(
    BuildContext context,
    Map<String, dynamic> componentes,
  ) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Map<String, int> piezasAsignadas = (alumnoActual.piezasUniforme ?? {}).map(
      (key, value) => MapEntry(key, value as int),
    );
    for (var pieza in componentes.keys) {
      piezasAsignadas.putIfAbsent(pieza, () => 0);
    }

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Asignar/Editar Piezas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...componentes.keys.map((pieza) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text('$pieza (\$${componentes[pieza]})'),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setDialogState(() {
                                    if ((piezasAsignadas[pieza] ?? 0) > 0) {
                                      piezasAsignadas[pieza] =
                                          piezasAsignadas[pieza]! - 1;
                                    }
                                  });
                                },
                              ),
                              Text(piezasAsignadas[pieza].toString()),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setDialogState(() {
                                    piezasAsignadas[pieza] =
                                        (piezasAsignadas[pieza] ?? 0) + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                    const Divider(),
                    ElevatedButton(
                      child: const Text('Asignar Uniforme Completo'),
                      onPressed: () {
                        setDialogState(() {
                          for (var pieza in componentes.keys) {
                            piezasAsignadas[pieza] = 1;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => navigator.pop(),
                ),
                ElevatedButton(
                  child: const Text('Guardar Cambios'),
                  onPressed: () => navigator.pop(piezasAsignadas),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('alumnos')
            .doc(alumnoActual.id)
            .update({'piezasUniforme': result});
        setState(() {
          alumnoActual = alumnoActual.copyWith(piezasUniforme: result);
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Piezas actualizadas.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  // --- FUNCIÓN PARA ASIGNAR TALLA DE BATA ---
  Future<void> _showAssignBataDialog(
    BuildContext context,
    Map<String, dynamic> preciosPorTalla,
  ) async {
    String? tallaSeleccionada;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Asignar Talla de Bata'),
          content: DropdownButtonFormField<String>(
            hint: const Text('Seleccione una talla'),
            items: preciosPorTalla.keys.map((String talla) {
              return DropdownMenuItem<String>(
                value: talla,
                child: Text('$talla - \$${preciosPorTalla[talla]}'),
              );
            }).toList(),
            onChanged: (newValue) => tallaSeleccionada = newValue,
            validator: (value) => value == null ? 'Seleccione una talla' : null,
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => navigator.pop(),
            ),
            ElevatedButton(
              child: const Text('Asignar'),
              onPressed: () {
                if (tallaSeleccionada != null) navigator.pop(tallaSeleccionada);
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('alumnos')
            .doc(alumnoActual.id)
            .update({'tallaBata': result});
        setState(() {
          alumnoActual = alumnoActual.copyWith(tallaBata: result);
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Talla asignada.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error al asignar talla: $e')),
        );
      }
    }
  }

  // --- FUNCIÓN GENÉRICA PARA AGREGAR PAGO ---
  Future<void> _showAddPaymentDialog(
    BuildContext context,
    String rubro,
    dynamic precioData,
    List<Pago> pagosDeEsteRubro,
  ) async {
    final formKey = GlobalKey<FormState>();
    final montoController = TextEditingController();
    final fechaController = TextEditingController();
    DateTime? selectedDate;
    String? selectedMetodo;
    final List<String> metodosDePago = ['Efectivo', 'Tarjeta'];
    bool esPagoTotal = false;

    double restante = 0;
    if (rubro == 'Bata' && alumnoActual.tallaBata != null) {
      final preciosPorTalla = Map<String, dynamic>.from(
        precioData['preciosPorTalla'],
      );
      final talla = alumnoActual.tallaBata!;
      final totalPagado = pagosDeEsteRubro.fold(
        0.0,
        (sum, pago) => sum + pago.monto,
      );
      final precioTotal = (preciosPorTalla[talla] as num?)?.toDouble() ?? 0.0;
      restante = precioTotal - totalPagado;
    } else if (rubro == 'Uniforme') {
      final componentes = Map<String, dynamic>.from(precioData['componentes']);
      double deudaTotal = 0;
      (alumnoActual.piezasUniforme ?? {}).forEach((pieza, cantidad) {
        deudaTotal += (componentes[pieza] as num? ?? 0) * (cantidad as int);
      });
      final totalPagado = pagosDeEsteRubro.fold(0.0, (sum, p) => sum + p.monto);
      restante = deudaTotal - totalPagado;
    } else if (precioData['monto'] != null) {
      final totalPagado = pagosDeEsteRubro.fold(
        0.0,
        (sum, pago) => sum + pago.monto,
      );
      final precioTotal = (precioData['monto'] as num).toDouble();
      restante = precioTotal - totalPagado;
    }
    montoController.text = restante > 0 ? restante.toStringAsFixed(2) : '0.00';

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Registrar Pago: $rubro'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            (v == null ||
                                v.isEmpty ||
                                double.tryParse(v) == null)
                            ? 'Monto inválido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: fechaController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Pago',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                              fechaController.text =
                                  "${picked.day}/${picked.month}/${picked.year}";
                            });
                          }
                        },
                        validator: (v) => v == null || v.isEmpty
                            ? 'Seleccione una fecha'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedMetodo,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(),
                        ),
                        items: metodosDePago
                            .map(
                              (m) => DropdownMenuItem<String>(
                                value: m,
                                child: Text(m),
                              ),
                            )
                            .toList(),
                        onChanged: (newValue) =>
                            setState(() => selectedMetodo = newValue),
                        validator: (v) =>
                            v == null ? 'Seleccione un método' : null,
                      ),
                      if (rubro != 'Uniforme')
                        SwitchListTile(
                          title: const Text('Pago Total'),
                          value: esPagoTotal,
                          onChanged: (bool value) =>
                              setState(() => esPagoTotal = value),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final pagoData = {
                    'rubro': rubro,
                    'monto': double.parse(montoController.text),
                    'fechaPago': Timestamp.fromDate(selectedDate!),
                    'metodoPago': selectedMetodo,
                    'tipo': esPagoTotal ? 'total' : 'parcial',
                    if (rubro == 'Bata') 'talla': alumnoActual.tallaBata,
                  };
                  try {
                    await FirebaseFirestore.instance
                        .collection('alumnos')
                        .doc(widget.alumno.id)
                        .collection('pagos')
                        .add(pagoData);
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    /* Manejar error */
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- FUNCIÓN PARA EDITAR PAGO ---
  Future<void> _showEditPaymentDialog(BuildContext context, Pago pago) async {
    final formKey = GlobalKey<FormState>();
    final montoController = TextEditingController(
      text: pago.monto.toStringAsFixed(2),
    );
    final fechaController = TextEditingController();
    DateTime selectedDate = pago.fechaPago.toDate();
    fechaController.text =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
    String? selectedMetodo = pago.metodoPago;
    bool esPagoTotal = pago.tipo == 'total';
    final List<String> metodosDePago = ['Efectivo', 'Tarjeta'];
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Editar Pago: ${pago.rubro}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            (v == null ||
                                v.isEmpty ||
                                double.tryParse(v) == null)
                            ? 'Monto inválido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: fechaController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Pago',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                              fechaController.text =
                                  "${picked.day}/${picked.month}/${picked.year}";
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedMetodo,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(),
                        ),
                        items: metodosDePago
                            .map(
                              (m) => DropdownMenuItem<String>(
                                value: m,
                                child: Text(m),
                              ),
                            )
                            .toList(),
                        onChanged: (newValue) =>
                            setState(() => selectedMetodo = newValue),
                      ),
                      SwitchListTile(
                        title: const Text('Pago Total'),
                        value: esPagoTotal,
                        onChanged: (bool value) =>
                            setState(() => esPagoTotal = value),
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
              onPressed: () => navigator.pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar Cambios'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final updatedData = {
                    'monto': double.parse(montoController.text),
                    'fechaPago': Timestamp.fromDate(selectedDate),
                    'metodoPago': selectedMetodo,
                    'tipo': esPagoTotal ? 'total' : 'parcial',
                  };
                  try {
                    await FirebaseFirestore.instance
                        .collection('alumnos')
                        .doc(widget.alumno.id)
                        .collection('pagos')
                        .doc(pago.id)
                        .update(updatedData);
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Pago actualizado.'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  } catch (e) {
                    /* Manejar error */
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- FUNCIÓN HISTORIAL DE PAGO ---
  void _showPaymentHistoryDialog(
    BuildContext context,
    String rubro,
    List<Pago> pagos,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pago.tipo == 'total')
                        Chip(
                          label: const Text('Total'),
                          backgroundColor: Colors.green[100],
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _showEditPaymentDialog(context, pago);
                        },
                        tooltip: 'Editar Pago',
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagos de ${alumnoActual.nombre}'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('alumnos')
            .doc(alumnoActual.id)
            .collection('pagos')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final Map<String, List<Pago>> pagosPorRubro = {};
          for (var doc in snapshot.data!.docs) {
            final pago = Pago.fromFirestore(doc);
            pagosPorRubro.putIfAbsent(pago.rubro, () => []).add(pago);
          }

          return ListView.builder(
            itemCount: rubrosDePago.length,
            itemBuilder: (context, index) {
              final rubro = rubrosDePago[index];
              final pagosDeEsteRubro = pagosPorRubro[rubro] ?? [];

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('precios')
                    .where('grado', isEqualTo: alumnoActual.grado)
                    .where('rubro', isEqualTo: rubro)
                    .limit(1)
                    .get(),
                builder: (context, precioSnapshot) {
                  if (precioSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text(rubro),
                      trailing: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (precioSnapshot.data == null ||
                      precioSnapshot.data!.docs.isEmpty) {
                    return ListTile(
                      title: Text(rubro),
                      trailing: const Text('Precio no definido'),
                    );
                  }

                  final precioData =
                      precioSnapshot.data!.docs.first.data()
                          as Map<String, dynamic>;
                  final totalPagado = pagosDeEsteRubro.fold(
                    0.0,
                    (sum, pago) => sum + pago.monto,
                  );

                  String estadoTexto;
                  Color estadoColor;
                  IconData estadoIcono;
                  Widget trailingWidget;
                  VoidCallback? onTapAction;

                  if (rubro == 'Uniforme') {
                    final componentes = Map<String, dynamic>.from(
                      precioData['componentes'],
                    );
                    double deudaTotal = 0;
                    if (alumnoActual.piezasUniforme != null) {
                      alumnoActual.piezasUniforme!.forEach((pieza, cantidad) {
                        deudaTotal +=
                            (componentes[pieza] as num? ?? 0) *
                            (cantidad as int);
                      });
                    }
                    final restante = deudaTotal - totalPagado;

                    if (alumnoActual.piezasUniforme == null ||
                        alumnoActual.piezasUniforme!.isEmpty) {
                      estadoTexto = 'Asignar Piezas';
                      estadoColor = Colors.grey;
                      estadoIcono = Icons.checkroom;
                      onTapAction = () =>
                          _showAssignUniformeDialog(context, componentes);
                      trailingWidget = Text(
                        estadoTexto,
                        style: TextStyle(
                          color: estadoColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } else {
                      estadoTexto = 'Restante \$${restante.toStringAsFixed(2)}';
                      estadoColor = restante <= 0
                          ? Colors.green
                          : (totalPagado > 0 ? Colors.blue : Colors.purple);
                      estadoIcono = restante <= 0
                          ? Icons.check_circle
                          : (totalPagado > 0
                                ? Icons.hourglass_top_outlined
                                : Icons.shopping_cart_checkout);

                      // ✅ LÓGICA DE ONTAP CORREGIDA
                      if (restante <= 0) {
                        onTapAction = () => _showPaymentHistoryDialog(
                          context,
                          rubro,
                          pagosDeEsteRubro,
                        );
                      } else {
                        onTapAction = () => _showAddPaymentDialog(
                          context,
                          rubro,
                          precioData,
                          pagosDeEsteRubro,
                        );
                      }

                      trailingWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            estadoTexto,
                            style: TextStyle(
                              color: estadoColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.blueGrey,
                              size: 20,
                            ),
                            tooltip: 'Editar Piezas Asignadas',
                            onPressed: () =>
                                _showAssignUniformeDialog(context, componentes),
                          ),
                        ],
                      );
                    }
                  } else if (rubro == 'Bata') {
                    final preciosPorTalla = Map<String, dynamic>.from(
                      precioData['preciosPorTalla'],
                    );
                    if (alumnoActual.tallaBata == null) {
                      estadoTexto = 'Asignar Talla';
                      estadoColor = Colors.grey;
                      estadoIcono = Icons.style_outlined;
                      onTapAction = () =>
                          _showAssignBataDialog(context, preciosPorTalla);
                    } else {
                      final talla = alumnoActual.tallaBata!;
                      final precioTotal =
                          (preciosPorTalla[talla] as num?)?.toDouble() ?? 0.0;
                      final restante = precioTotal - totalPagado;
                      if (restante <= 0) {
                        estadoTexto =
                            'Pagado Total (\$${precioTotal.toStringAsFixed(2)})';
                        estadoColor = Colors.green;
                        estadoIcono = Icons.check_circle;
                        onTapAction = () => _showPaymentHistoryDialog(
                          context,
                          rubro,
                          pagosDeEsteRubro,
                        );
                      } else {
                        estadoTexto =
                            'Restante \$${restante.toStringAsFixed(2)}';
                        estadoColor = totalPagado > 0
                            ? Colors.blue
                            : Colors.orange;
                        estadoIcono = totalPagado > 0
                            ? Icons.hourglass_top_outlined
                            : Icons.hourglass_empty;
                        onTapAction = () => _showAddPaymentDialog(
                          context,
                          rubro,
                          precioData,
                          pagosDeEsteRubro,
                        );
                      }
                    }
                    trailingWidget = Text(
                      estadoTexto,
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else {
                    final precioTotal = (precioData['monto'] as num).toDouble();
                    final restante = precioTotal - totalPagado;
                    if (restante <= 0) {
                      estadoTexto =
                          'Pagado Total \$${precioTotal.toStringAsFixed(2)}';
                      estadoColor = Colors.green;
                      estadoIcono = Icons.check_circle;
                      onTapAction = () => _showPaymentHistoryDialog(
                        context,
                        rubro,
                        pagosDeEsteRubro,
                      );
                    } else {
                      estadoTexto = 'Restante \$${restante.toStringAsFixed(2)}';
                      estadoColor = totalPagado > 0
                          ? Colors.blue
                          : Colors.orange;
                      estadoIcono = totalPagado > 0
                          ? Icons.hourglass_top_outlined
                          : Icons.hourglass_empty;
                      onTapAction = () => _showAddPaymentDialog(
                        context,
                        rubro,
                        precioData,
                        pagosDeEsteRubro,
                      );
                    }
                    trailingWidget = Text(
                      estadoTexto,
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  return ListTile(
                    leading: Icon(estadoIcono, color: estadoColor),
                    title: Text(rubro),
                    trailing: trailingWidget,
                    onTap: onTapAction,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
