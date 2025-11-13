// lib/screens/app_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:proyect_movil/screens/initial_home_screen.dart';

class AppNavigationScreen extends StatelessWidget {
  const AppNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Ya no hay AppBar ni BottomNavigationBar
      // El fondo lo manejará la propia InitialHomeScreen
      body: InitialHomeScreen(),
    );
  }
}