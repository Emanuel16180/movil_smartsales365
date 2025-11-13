import 'package:flutter/material.dart';
import '../widgets/cart_body.dart';

class CartModalScreen extends StatelessWidget {
  const CartModalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8E8), // fondo general claro
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: const Color(0xFF8B1E3F), // bordó oscuro
        foregroundColor: Colors.white, // color del texto e ícono
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const CartBody(),
    );
  }
}
