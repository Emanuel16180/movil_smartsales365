// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:proyect_movil/screens/garantias_screen.dart';
import 'package:proyect_movil/screens/mis_compras_screen.dart';
// --- 1. Importa el nuevo widget ---
import 'package:proyect_movil/screens/profile_data_tab.dart'; 
import 'package:proyect_movil/screens/favorites_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Mis Datos'),
            Tab(text: 'Favoritos'),
            Tab(text: 'Compras'),
            Tab(text: 'Garantías'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // --- 2. Reemplaza el placeholder por el nuevo widget ---
          ProfileDataTab(),

          FavoritesTab(), 

          // 3. Tu pantalla existente "Mis Compras"
          MisComprasScreen(),

          // 4. Tu pantalla existente "Garantías"
          GarantiasScreen(),
        ],
      ),
    );
  }

  // --- 5. Ya no necesitas el método _buildMisDatosPlaceholder() ---
  // ... puedes borrarlo ...
}