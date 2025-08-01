import 'package:flutter/material.dart';
//firestore
import 'package:cloud_firestore/cloud_firestore.dart';

class PreciosScreen extends StatefulWidget {
  const PreciosScreen({super.key});

  @override
  State<PreciosScreen> createState() => _PreciosScreenState();
}

class _PreciosScreenState extends State<PreciosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Precios'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('precios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error al leer de Firestore: ${snapshot.error}');
            return const Center(child: Text('Ocurrió un error'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay precios registrados.'));
          }

          final precios = snapshot.data!.docs.map((doc) => doc.data()).toList();

          return ListView.builder(
            itemCount: precios.length,
            itemBuilder: (context, index) {
              final precio = precios[index];
              return ListTile(
                title: Text(precio['nombre'] ?? 'Sin nombre'),
                subtitle: Text('\$${precio['monto'] ?? '0.00'}'),
              );
            },
          );
        },
      ),
    );
  }
}
