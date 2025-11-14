import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pago.dart';

class ResumenColegiaturasWidget extends StatefulWidget {
  const ResumenColegiaturasWidget({super.key});

  @override
  State<ResumenColegiaturasWidget> createState() =>
      _ResumenColegiaturasWidgetState();
}

class _ResumenColegiaturasWidgetState extends State<ResumenColegiaturasWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('pagos')
          .where('rubro', isEqualTo: 'Colegiatura')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 230,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar los datos'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              height: 210,
              child: Center(
                child: Text('Aún no hay pagos de colegiatura registrados.'),
              ),
            ),
          );
        }

        double totalGeneral = 0;
        double totalEfectivo = 0;
        double totalTarjeta = 0;

        for (final pagoDoc in snapshot.data!.docs) {
          final pago = Pago.fromFirestore(pagoDoc);
          totalGeneral += pago.monto;
          if (pago.metodoPago == 'Efectivo') {
            totalEfectivo += pago.monto;
          } else if (pago.metodoPago == 'Tarjeta') {
            totalTarjeta += pago.monto;
          }
        }

        // Consulta de gastos (async en StreamBuilder)
        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('gastos').get(),
          builder: (context, gastosSnapshot) {
            double totalGastos = 0;
            if (gastosSnapshot.hasData) {
              for (final gastoDoc in gastosSnapshot.data!.docs) {
                final data = gastoDoc.data();
                totalGastos += (data['monto'] as num).toDouble();
              }
            }
            double totalDisponible = totalGeneral - totalGastos;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Card(
                    color: Colors.green[50],
                    child: ListTile(
                      leading: const Icon(Icons.calculate, color: Colors.green),
                      title: const Text(
                        'Total Disponible (Colegiaturas - Gastos)',
                      ),
                      trailing: Text(
                        '\$${totalDisponible.toStringAsFixed(2)}',
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
                    color: Colors.red[50],
                    child: ListTile(
                      leading: const Icon(Icons.money_off, color: Colors.red),
                      title: const Text('Total Gastos'),
                      trailing: Text(
                        '-\$${totalGastos.toStringAsFixed(2)}',
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
        );
      },
    );
  }
}
