import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pago.dart';

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  String? _gradoSeleccionado;
  final List<String> _grados = ['Maternal', 'Kinder 1', 'Kinder 2', 'Kinder 3'];
  final List<String> _rubros = [
    'Inscripción',
    'Material Escolar',
    'Libros',
    'Uniforme',
    'Bata',
    // 'Colegiatura', // Excluido según tu requerimiento
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
            setState(() => _gradoSeleccionado = value);
            Navigator.of(context).pop(value);
          },
          decoration: const InputDecoration(labelText: 'Grado'),
        ),
      ),
    );
    if (grado != null) {
      setState(() => _gradoSeleccionado = grado);
    }
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
              tooltip: 'Cambiar grado',
              onPressed: () => _seleccionarGrado(context),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: _rubros.map((rubro) => Tab(text: rubro)).toList(),
            labelColor: Colors.white, // Texto seleccionado en blanco
            indicatorColor: Colors.white,
            unselectedLabelColor:
                Colors.white70, // Texto no seleccionado en blanco tenue
          ),
        ),
        body: TabBarView(
          children: _rubros.map((rubro) {
            return _PagosPorRubro(grado: _gradoSeleccionado!, rubro: rubro);
          }).toList(),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final tabController = DefaultTabController.of(context);
                if (tabController != null) {
                  final rubroSeleccionado = _rubros[tabController.index];
                  // Aquí puedes implementar la lógica para registrar un gasto.
                  // Por ejemplo, navegar a una nueva pantalla:
                  // Navigator.of(context).push(MaterialPageRoute(
                  //   builder: (context) => RegistrarGastoScreen(rubro: rubroSeleccionado),
                  // ));

                  // Como ejemplo, mostramos un SnackBar.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registrar gasto para: $rubroSeleccionado'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
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

class _PagosPorRubro extends StatelessWidget {
  final String grado;
  final String rubro;

  const _PagosPorRubro({required this.grado, required this.rubro});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('alumnos')
          .where('grado', isEqualTo: grado)
          .snapshots(),
      builder: (context, alumnosSnapshot) {
        if (alumnosSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (alumnosSnapshot.hasError) {
          return Center(child: Text('Error: ${alumnosSnapshot.error}'));
        }
        final alumnos = alumnosSnapshot.data?.docs ?? [];
        if (alumnos.isEmpty) {
          return const Center(child: Text('No hay alumnos en este grado.'));
        }
        final alumnoIds = alumnos.map((doc) => doc.id).toList();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collectionGroup('pagos')
              .where('rubro', isEqualTo: rubro)
              .snapshots(),
          builder: (context, pagosSnapshot) {
            if (pagosSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (pagosSnapshot.hasError) {
              return Center(child: Text('Error: ${pagosSnapshot.error}'));
            }

            double total = 0;
            final pagos = <Pago>[];

            if (pagosSnapshot.hasData) {
              for (var doc in pagosSnapshot.data!.docs) {
                final parent = doc.reference.parent.parent;
                if (parent != null && alumnoIds.contains(parent.id)) {
                  final pago = Pago.fromFirestore(doc);
                  pagos.add(pago);
                  total += pago.monto;
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Card(
                    color: Colors.green[50],
                    child: ListTile(
                      leading: const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                      title: Text('Total de pagos en "$rubro"'),
                      trailing: Text(
                        '\$${total.toStringAsFixed(2)}',
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
                        '\$${pagos.where((p) => p.metodoPago == "Efectivo").fold<double>(0, (s, p) => s + p.monto).toStringAsFixed(2)}',
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
                        Icons.credit_card,
                        color: Colors.blue,
                      ),
                      title: const Text('Total en tarjeta'),
                      trailing: Text(
                        '\$${pagos.where((p) => p.metodoPago == "Tarjeta").fold<double>(0, (s, p) => s + p.monto).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pagos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No hay pagos registrados para este rubro.',
                        ),
                      ),
                    )
                  else
                    ...pagos.map((pago) {
                      final fecha = pago.fechaPago.toDate();
                      final fechaFormateada =
                          "${fecha.day}/${fecha.month}/${fecha.year}";
                      return Card(
                        child: ListTile(
                          title: Text('\$${pago.monto.toStringAsFixed(2)}'),
                          subtitle: Text(
                            '$fechaFormateada - ${pago.metodoPago}',
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
