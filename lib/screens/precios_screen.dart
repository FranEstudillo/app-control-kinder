import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreciosScreen extends StatefulWidget {
  const PreciosScreen({super.key});

  @override
  State<PreciosScreen> createState() => _PreciosScreenState();
}

class _PreciosScreenState extends State<PreciosScreen> {
  final List<String> gradosOrdenados = [
    'Maternal',
    'Kínder 1',
    'Kínder 2',
    'Kínder 3',
  ];

  Future<void> _mostrarDialogoEditarPrecio(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data()!;
    final rubro = data['rubro'] as String;
    final formKey = GlobalKey<FormState>();
    final Map<String, TextEditingController> controllers = {};

    // Función para construir el diálogo
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Editar Precios de $rubro'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lógica para construir el formulario según el tipo de rubro
                  if (data.containsKey('monto'))
                    TextFormField(
                      controller: (controllers['monto'] = TextEditingController(
                        text: (data['monto'] as num).toString(),
                      )),
                      decoration: const InputDecoration(labelText: 'Monto'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo requerido'
                          : null,
                    )
                  else if (rubro == 'Bata' &&
                      data.containsKey('preciosPorTalla'))
                    ...(data['preciosPorTalla'] as Map<String, dynamic>).entries
                        .map((entry) {
                          return TextFormField(
                            controller: (controllers[entry.key] =
                                TextEditingController(
                                  text: (entry.value as num).toString(),
                                )),
                            decoration: InputDecoration(
                              labelText: 'Talla ${entry.key}',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo requerido'
                                : null,
                          );
                        })
                  else if (rubro == 'Uniforme' &&
                      data.containsKey('componentes'))
                    ...(data['componentes'] as Map<String, dynamic>).entries
                        .map((entry) {
                          return TextFormField(
                            controller: (controllers[entry.key] =
                                TextEditingController(
                                  text: (entry.value as num).toString(),
                                )),
                            decoration: InputDecoration(labelText: entry.key),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo requerido'
                                : null,
                          );
                        }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final Map<String, dynamic> nuevosValores = {};

                  // Recolectar nuevos valores
                  if (data.containsKey('monto')) {
                    nuevosValores['monto'] = double.parse(
                      controllers['monto']!.text,
                    );
                  } else if (rubro == 'Bata') {
                    final preciosPorTalla = {
                      for (var entry in controllers.entries)
                        entry.key: double.parse(entry.value.text),
                    };
                    nuevosValores['preciosPorTalla'] = preciosPorTalla;
                  } else if (rubro == 'Uniforme') {
                    final componentes = {
                      for (var entry in controllers.entries)
                        entry.key: double.parse(entry.value.text),
                    };
                    nuevosValores['componentes'] = componentes;
                  }

                  // Actualizar en Firestore
                  await FirebaseFirestore.instance
                      .collection('precios')
                      .doc(doc.id)
                      .update(nuevosValores);

                  if (mounted) Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Guardar'),
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
        title: const Text('Configuración de Precios'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('precios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay precios definidos.'));
          }

          final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
          preciosPorGrado = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data();
            final grado = data['grado'] as String?;
            if (grado != null) {
              preciosPorGrado.putIfAbsent(grado, () => []).add(doc);
            }
          }

          return ListView.builder(
            itemCount: gradosOrdenados.length,
            itemBuilder: (context, index) {
              final grado = gradosOrdenados[index];
              final preciosDelGrado = preciosPorGrado[grado] ?? [];

              if (preciosDelGrado.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Card(
                  elevation: 2,
                  child: ExpansionTile(
                    title: Text(
                      grado,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepPurple,
                      ),
                    ),
                    initiallyExpanded: true,
                    children: preciosDelGrado.map((doc) {
                      final data = doc.data();
                      final rubro = data['rubro'] as String? ?? 'Sin Rubro';
                      Widget detallePrecio;
                      IconData icono = Icons.help_outline;

                      if (rubro == 'Bata' &&
                          data.containsKey('preciosPorTalla')) {
                        final preciosTalla =
                            data['preciosPorTalla'] as Map<String, dynamic>;
                        final detalles = preciosTalla.entries.map((entry) {
                          return Text(
                            '  • Talla ${entry.key}: \$${(entry.value as num).toStringAsFixed(2)}',
                          );
                        }).toList();
                        detallePrecio = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: detalles,
                        );
                        icono = Icons.checkroom;
                      } else if (rubro == 'Uniforme' &&
                          data.containsKey('componentes')) {
                        final componentes =
                            data['componentes'] as Map<String, dynamic>;
                        final detalles = componentes.entries.map((entry) {
                          return Text(
                            '  • ${entry.key}: \$${(entry.value as num).toStringAsFixed(2)}',
                          );
                        }).toList();
                        detallePrecio = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: detalles,
                        );
                        icono = Icons.checkroom;
                      } else if (data.containsKey('monto')) {
                        final monto = (data['monto'] as num).toDouble();
                        detallePrecio = Text(
                          '\$${monto.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                        icono = Icons.attach_money;
                      } else {
                        detallePrecio = const Text('Estructura no reconocida');
                      }

                      return ListTile(
                        leading: Icon(icono, color: Colors.deepPurple[200]),
                        title: Text(
                          rubro,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: detallePrecio,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () =>
                              _mostrarDialogoEditarPrecio(context, doc),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
