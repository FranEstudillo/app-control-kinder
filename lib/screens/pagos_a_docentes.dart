import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
//import '../widgets/resumen_colegiaturas_widget.dart';
import '../models/gasto.dart';
import '../utils/totales_utils.dart';

class PagosADocentesScreen extends StatefulWidget {
  const PagosADocentesScreen({super.key});

  @override
  State<PagosADocentesScreen> createState() => _PagosADocentesScreenState();
}

class _PagosADocentesScreenState extends State<PagosADocentesScreen> {
  late Future<Map<String, double>> _totalesFuture;

  @override
  void initState() {
    super.initState();
    _totalesFuture = getTotalesColegiaturasYGastos();
  }

  Future<void> _mostrarPopupRegistrarGasto() async {
    final formKey = GlobalKey<FormState>();
    final montoController = TextEditingController();
    final fechaController = TextEditingController();
    final comentarioController = TextEditingController();
    DateTime? fechaSeleccionada;
    String fuenteSeleccionada = 'Efectivo'; // Valor por defecto

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar Gasto a Docente'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          if (value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Ingrese un monto válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: fechaController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha del Gasto',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
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
                      TextFormField(
                        controller: comentarioController,
                        decoration: const InputDecoration(
                          labelText: 'Comentario',
                          prefixIcon: Icon(Icons.comment),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese un comentario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Fuente del Gasto',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => navigator.pop(),
                ),
                ElevatedButton(
                  child: const Text('Guardar Gasto'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final gastoData = {
                        'monto': double.parse(montoController.text),
                        'fecha': Timestamp.fromDate(fechaSeleccionada!),
                        'comentario': comentarioController.text,
                        'fuente': fuenteSeleccionada,
                      };

                      try {
                        await FirebaseFirestore.instance
                            .collection('gastos')
                            .add(gastoData);
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Gasto guardado con éxito.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        scaffoldMessenger.showSnackBar(
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos a Docentes'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<Map<String, double>>(
              future: _totalesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  );
                }
                final totales = snapshot.data!;
                return Column(
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
                          '\$${totales['totalGeneral']!.toStringAsFixed(2)}',
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
                          '\$${totales['totalEfectivo']!.toStringAsFixed(2)}',
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
                          '\$${totales['totalTarjeta']!.toStringAsFixed(2)}',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            //const ResumenColegiaturasWidget(),
            const Divider(thickness: 1.5),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Historial de Gastos a Docentes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('gastos')
                  .where('comentario', isNull: false)
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar los gastos.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No hay gastos registrados.'),
                    ),
                  );
                }

                final gastos = snapshot.data!.docs.map((doc) {
                  final data = doc.data();
                  return Gasto(
                    id: doc.id,
                    monto: (data['monto'] as num).toDouble(),
                    comentario: data['comentario'],
                    fecha: data['fecha'],
                    fuente: data['fuente'],
                  );
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gastos.length,
                  itemBuilder: (context, index) {
                    final gasto = gastos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[100],
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          '\$${gasto.monto.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${gasto.comentario}\n${DateFormat('dd/MM/yyyy').format(gasto.fecha.toDate())} - ${gasto.fuente}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarPopupRegistrarGasto,
        tooltip: 'Registrar Gasto',
        backgroundColor: Colors.orange.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
