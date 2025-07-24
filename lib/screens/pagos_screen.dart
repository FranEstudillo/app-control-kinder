import 'package:flutter/material.dart';
//modelos
import 'package:app_control_kinder_v4/models/alumno.dart';
import 'package:app_control_kinder_v4/models/pago.dart';
//firestore
import 'package:cloud_firestore/cloud_firestore.dart';

// Nueva pantalla para mostrar los rubros de pago de un alumno.
class PagosScreen extends StatefulWidget {
  final Alumno alumno;

  const PagosScreen({super.key, required this.alumno});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
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
        title: Text('Pagos de ${widget.alumno.nombre}'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('alumnos')
            .doc(widget.alumno.id)
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
                        .doc(widget.alumno.id)
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
      context: context, // Este es el context del Scaffold
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pago.tipo == 'total')
                        Chip(
                          label: const Text(
                            'Total',
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.green[100],
                          padding: EdgeInsets.zero,
                        ),
                      const SizedBox(width: 8),
                      // --- INICIO DEL CAMBIO ---
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          // Cerramos el historial para abrir el de edición
                          Navigator.of(context).pop();
                          _showEditPaymentDialog(
                            this.context,
                            pago,
                          ); // Usamos el context del State
                        },
                        tooltip: 'Editar Pago',
                      ),
                      // --- FIN DEL CAMBIO ---
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
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo de historial
              },
            ),
          ],
        );
      },
    );
  }

  // Método para mostrar el diálogo de edición de pago.
  Future<void> _showEditPaymentDialog(BuildContext context, Pago pago) async {
    final formKey = GlobalKey<FormState>();
    // Precargamos los datos del pago existente
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
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != selectedDate) {
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
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(),
                        ),
                        items: metodosDePago.map((String metodo) {
                          return DropdownMenuItem<String>(
                            value: metodo,
                            child: Text(metodo),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() => selectedMetodo = newValue);
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Pago Total'),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pago actualizado correctamente.'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  } catch (e) {
                    // Manejo de errores
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
