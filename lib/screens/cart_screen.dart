// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:proyect_movil/widgets/cart_body.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // Fondo gris claro
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Colors.white, // Fondo blanco
        foregroundColor: Colors.black, // Texto e íconos negros
        elevation: 1, // Sombra ligera
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Icono de atrás
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const CartBody(),
    );
  }
}