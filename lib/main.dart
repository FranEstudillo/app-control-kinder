import 'package:flutter/material.dart';

void main() {
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber,
          title: Text('Mi primer ABC', style: TextStyle(color: Colors.white)),
          bottom: TabBar(
            tabs: [
              //aquí se agregan las pestañas
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.settings), text: 'Opciones'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.blueGrey[600],
          ),
        ),
        body: TabBarView(
          children: [
            Center(child: Text("Home Screen")),
            Center(child: Text("Settings Screen")),
          ],
        ),
      ),
    );
  }
}
