// lib/screens/app_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:proyect_movil/screens/cart_screen.dart';
import 'package:proyect_movil/screens/garantias_screen.dart';
import 'package:proyect_movil/screens/initial_home_screen.dart';
import 'package:proyect_movil/screens/mis_compras_screen.dart';

class AppNavigationScreen extends StatefulWidget {
  const AppNavigationScreen({super.key});

  @override
  State<AppNavigationScreen> createState() => _AppNavigationScreenState();
}

class _AppNavigationScreenState extends State<AppNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    InitialHomeScreen(),
    GarantiasScreen(),
    MisComprasScreen(),
  ];

  // Títulos para la AppBar
  static const List<String> _appBarTitles = <String>[
    'SmartSales365', // <--- ¡CAMBIO REALIZADO!
    'Mis Garantías',
    'Mis Compras',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8E8),
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        backgroundColor: const Color(0xFF8B1E3F),
        foregroundColor: Colors.white,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Comprar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'Garantías',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Mis Compras',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF8B1E3F),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}