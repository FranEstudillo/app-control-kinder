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

          final Map<String, List<QueryDocumentSnapshot>> preciosPorGrado = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data(); // Obtenemos los datos
            // Hacemos el cast a Map para poder leer el campo 'grado' de forma segura
            final grado = (data as Map<String, dynamic>)['grado'] as String?;
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
                      // ✅ CORRECCIÓN PRINCIPAL: Hacemos el cast aquí
                      final data = doc.data() as Map<String, dynamic>;
                      final rubro = data['rubro'] as String? ?? 'Sin Rubro';
                      Widget detallePrecio;
                      IconData icono = Icons.help_outline;

                      if (rubro == 'Bata' &&
                          data.containsKey('preciosPorTalla')) {
                        final preciosTalla =
                            data['preciosPorTalla'] as Map<String, dynamic>;
                        final detalles = preciosTalla.entries.map((entry) {
                          return Text(
                            '  • ${entry.key}: \$${(entry.value as num).toStringAsFixed(2)}',
                          );
                        }).toList();
                        detallePrecio = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: detalles,
                        );
                        icono = Icons.style;
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
                        onTap: () {
                          // Lógica para editar (futuro)
                        },
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
