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

  // --- FUNCIÓN PARA ASIGNAR/EDITAR PIEZAS DE UNIFORME (CON LÓGICA DE DESCUENTO) ---
  Future<void> _showAssignUniformeDialog(
    BuildContext context,
    Map<String, dynamic> componentes,
    double precioPaquete,
  ) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Map<String, int> piezasAsignadas = (alumnoActual.piezasUniforme ?? {}).map(
      (key, value) => MapEntry(key, value as int),
    );
    for (var pieza in componentes.keys) {
      piezasAsignadas.putIfAbsent(pieza, () => 0);
    }

    // Variable para controlar si el descuento del paquete está activo
    bool paqueteCompletoActivo = piezasAsignadas.values.every(
      (cantidad) => cantidad >= 1,
    );

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double calcularDeudaTotal() {
              double total = 0;
              if (paqueteCompletoActivo) {
                total += precioPaquete;
                piezasAsignadas.forEach((pieza, cantidad) {
                  if (cantidad > 1) {
                    total += (componentes[pieza] as num) * (cantidad - 1);
                  }
                });
              } else {
                piezasAsignadas.forEach((pieza, cantidad) {
                  total += (componentes[pieza] as num) * cantidad;
                });
              }
              return total;
            }

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
                                onPressed: () => setDialogState(() {
                                  if ((piezasAsignadas[pieza] ?? 0) > 0) {
                                    piezasAsignadas[pieza] =
                                        piezasAsignadas[pieza]! - 1;
                                  }
                                  paqueteCompletoActivo = false;
                                }),
                              ),
                              Text(piezasAsignadas[pieza].toString()),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setDialogState(
                                  () => piezasAsignadas[pieza] =
                                      (piezasAsignadas[pieza] ?? 0) + 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Aplicar Precio Paquete'),
                      subtitle: Text(
                        'Precio especial: \$${precioPaquete.toStringAsFixed(2)}',
                      ),
                      value: paqueteCompletoActivo,
                      onChanged: (value) {
                        setDialogState(() {
                          paqueteCompletoActivo = value;
                          if (value) {
                            for (var pieza in componentes.keys) {
                              if ((piezasAsignadas[pieza] ?? 0) == 0) {
                                piezasAsignadas[pieza] = 1;
                              }
                            }
                          }
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text(
                        'Deuda Total Calculada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '\$${calcularDeudaTotal().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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

  // --- OTRAS FUNCIONES DE DIÁLOGO ---
  // ... (Aquí van las funciones que ya teníamos: _showAddPaymentDialog, _showAssignBataDialog, etc.)

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

                  if (rubro == 'Uniforme') {
                    final componentes = Map<String, dynamic>.from(
                      precioData['componentes'],
                    );
                    final precioPaquete =
                        (precioData['precioPaquete'] as num?)?.toDouble() ??
                        0.0;

                    double deudaTotal = 0;
                    if (alumnoActual.piezasUniforme != null) {
                      final piezas = alumnoActual.piezasUniforme!;
                      final esPaquete = piezas.values.every(
                        (cantidad) => (cantidad as int) >= 1,
                      );

                      if (esPaquete && precioPaquete > 0) {
                        deudaTotal += precioPaquete;
                        piezas.forEach((pieza, cantidad) {
                          if ((cantidad as int) > 1) {
                            deudaTotal +=
                                (componentes[pieza] as num? ?? 0) *
                                (cantidad - 1);
                          }
                        });
                      } else {
                        piezas.forEach((pieza, cantidad) {
                          deudaTotal +=
                              (componentes[pieza] as num? ?? 0) *
                              (cantidad as int);
                        });
                      }
                    }

                    final restante = deudaTotal - totalPagado;

                    if (alumnoActual.piezasUniforme == null ||
                        alumnoActual.piezasUniforme!.isEmpty) {
                      estadoTexto = 'Asignar Piezas';
                      estadoColor = Colors.grey;
                      estadoIcono = Icons.checkroom;
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
                      trailingWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              estadoTexto,
                              style: TextStyle(
                                color: estadoColor,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.blueGrey,
                              size: 20,
                            ),
                            tooltip: 'Editar Piezas Asignadas',
                            onPressed: () => _showAssignUniformeDialog(
                              context,
                              componentes,
                              precioPaquete,
                            ),
                          ),
                        ],
                      );
                    }
                  } else {
                    // ... (La lógica para los demás rubros no cambia)
                  }

                  return ListTile(
                    // ... (El resto del ListTile no cambia)
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
