import 'package:flutter/material.dart';
// Importamos firestore
import 'package:cloud_firestore/cloud_firestore.dart';
// Importamos los modelos de Pago y Gasto
import '../models/pago.dart';
import '../models/gasto.dart';

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
