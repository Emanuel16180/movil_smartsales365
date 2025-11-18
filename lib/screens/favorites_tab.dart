// lib/screens/favorites_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyect_movil/providers/favorites_provider.dart';
import 'package:proyect_movil/widgets/product_card.dart';
import 'package:sizer/sizer.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  
  @override
  void initState() {
    super.initState();
    // Cargar favoritos al entrar a la pestaña
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoritesProvider>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final favorites = favoritesProvider.favoriteProducts;

    return RefreshIndicator(
      onRefresh: () async {
        await favoritesProvider.loadFavorites();
      },
      color: Theme.of(context).colorScheme.primary,
      child: favoritesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? Stack(
                  children: [
                    ListView(physics: const AlwaysScrollableScrollPhysics()), // Para que funcione el Refresh
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes favoritos aún.',
                            style: TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65, // Mismo ratio que en Home
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 3.w,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: favorites[index]);
                  },
                ),
    );
  }
}