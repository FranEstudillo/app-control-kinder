import 'package:flutter/material.dart'; // This line is already correct and points to the correct package.
// import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
// import 'dart:io';
// Importar Modelos
// import 'package:app_control_kinder_v4/models/alumno.dart';
// import 'package:app_control_kinder_v4/models/gasto.dart';
// import 'package:app_control_kinder_v4/models/pago.dart';
// Importar Screens
import 'package:app_control_kinder_v4/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
