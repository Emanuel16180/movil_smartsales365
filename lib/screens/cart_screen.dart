import 'package:flutter/material.dart';
import 'package:proyect_movil/widgets/cart_body.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8E8), // fondo claro
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: const Color(0xFF8B1E3F), // bordó oscuro
        foregroundColor: Colors.white, // ícono y texto blanco
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const CartBody(),
    );
  }
}
