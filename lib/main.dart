// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyect_movil/screens/login_screen.dart';
import 'services/cart_service.dart';
import 'providers/favorites_provider.dart'; // <-- 1. IMPORTAR
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:sizer/sizer.dart';
import 'package:proyect_movil/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Stripe.publishableKey = 'pk_test_51S1Zev5WdnUcbFfNgdPgBjQpNowJOyvDAIySUdpXrVmRftfGjVglfMPXp1vpeNUZPhskccm4OSS9BvU242zKJ6qC00AQaNAbE6';
  await Stripe.instance.applySettings();
  await NotificationService().init();
  
  final cartService = CartService();
  await cartService.loadCartFromLocalStorage();

  runApp(
    MultiProvider( // <-- 2. CAMBIAR A MULTIPROVIDER
      providers: [
        ChangeNotifierProvider.value(value: cartService),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..loadFavorites()), // <-- 3. AGREGAR FAVORITES
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'SmartSales365',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3A579B),
              surface: const Color(0xFFF5F5F5),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            cardColor: Colors.white,
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}