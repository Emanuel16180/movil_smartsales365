// lib/screens/cart_modal_screen.dart
import 'package:flutter/material.dart';
import '../widgets/cart_body.dart';

class CartModalScreen extends StatelessWidget {
  const CartModalScreen({super.key});

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
          icon: const Icon(Icons.close), // Icono de cerrar para modales
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const CartBody(),
    );
  }
}