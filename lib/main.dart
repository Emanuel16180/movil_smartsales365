import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyect_movil/screens/login_screen.dart'; 
import 'services/cart_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:sizer/sizer.dart'; // <-- 1. Importar Sizer

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Stripe.publishableKey = 'pk_test_51S1Zev5WdnUcbFfNgdPgBjQpNowJOyvDAIySUdpXrVmRftfGjVglfMPXp1vpeNUZPhskccm4OSS9BvU242zKJ6qC00AQaNAbE6';
  
  await Stripe.instance.applySettings();
  final cartService = CartService();
  await cartService.loadCartFromLocalStorage(); 

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
    // --- 2. Envolver MaterialApp con Sizer ---
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'SmartSales365', // Actualizado
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // Definimos un tema base que coincide con la imagen
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3A579B), // Azul primario
              background: const Color(0xFFF5F5F5), // Fondo claro
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            cardColor: Colors.white,
          ),
          home: const LoginScreen(), // Inicia en el Login
        );
      },
    );
    // -------------------------------------
  }
}