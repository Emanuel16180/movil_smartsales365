// lib/providers/favorites_provider.dart
import 'package:flutter/material.dart';
import 'package:proyect_movil/models/product_model.dart';
import 'package:proyect_movil/services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _service = FavoritesService();
  
  List<Product> _favoriteProducts = [];
  // Usamos un Set de IDs para búsqueda rápida (O(1)) al pintar los corazones
  Set<int> _favoriteIds = {};
  bool _isLoading = false;

  List<Product> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;

  // Verifica si un producto es favorito
  bool isFavorite(int productId) {
    return _favoriteIds.contains(productId);
  }

  // Cargar favoritos iniciales
  Future<void> loadFavorites() async {
    _isLoading = true;
    // notifyListeners(); // Opcional: si quieres mostrar loading general
    
    try {
      _favoriteProducts = await _service.getFavorites();
      _favoriteIds = _favoriteProducts.map((p) => p.id).toSet();
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Acción de dar/quitar like
  Future<void> toggleFavorite(Product product) async {
    // Optimistic UI: Actualizamos la interfaz ANTES de que responda el servidor
    final isCurrentlyFavorite = _favoriteIds.contains(product.id);

    if (isCurrentlyFavorite) {
      _favoriteIds.remove(product.id);
      _favoriteProducts.removeWhere((p) => p.id == product.id);
    } else {
      _favoriteIds.add(product.id);
      _favoriteProducts.add(product);
    }
    notifyListeners(); // Actualiza la UI inmediatamente

    try {
      // Llamada real al servidor
      final serverSaysFavorite = await _service.toggleFavorite(product.id);
      
      // Verificación de consistencia (opcional, por si falló la lógica optimista)
      if (serverSaysFavorite != !isCurrentlyFavorite) {
        // Si el servidor dice algo distinto, corregimos (rollback)
        if (serverSaysFavorite) {
             _favoriteIds.add(product.id);
             if (!_favoriteProducts.any((p) => p.id == product.id)) {
               _favoriteProducts.add(product);
             }
        } else {
             _favoriteIds.remove(product.id);
             _favoriteProducts.removeWhere((p) => p.id == product.id);
        }
        notifyListeners();
      }

    } catch (e) {
      // Si falla, revertimos el cambio
      if (isCurrentlyFavorite) {
        _favoriteIds.add(product.id);
        _favoriteProducts.add(product);
      } else {
        _favoriteIds.remove(product.id);
        _favoriteProducts.removeWhere((p) => p.id == product.id);
      }
      notifyListeners();
      rethrow; // Para manejar el error en la UI si es necesario
    }
  }
}