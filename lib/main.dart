import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyect_movil/screens/login_screen.dart'; // Importa LoginScreen
import 'services/cart_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. TU NUEVA LLAVE PUBLICA DE STRIPE
  Stripe.publishableKey = 'pk_test_51S1Zev5WdnUcbFfNgdPgBjQpNowJOyvDAIySUdpXrVmRftfGjVglfMPXp1vpeNUZPhskccm4OSS9BvU242zKJ6qC00AQaNAbE6';
  
  await Stripe.instance.applySettings();
  final cartService = CartService();
  await cartService.loadCartFromLocalStorage(); // Cargar al inicio

  runApp(
    ChangeNotifierProvider.value(
      value: cartService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App E-commerce',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Inicia en el Login
    );
  }
}