import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8E8), // fondo claro bordó
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF8B1E3F), // bordó oscuro
        foregroundColor: Colors.white, // texto blanco
      ),
      body: const Center(
        child: Text(
          '¡Bienvenido!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B1E3F), // texto en color bordó
          ),
        ),
      ),
    );
  }
}
