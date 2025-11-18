// lib/services/favorites_service.dart
import 'package:dio/dio.dart';
import 'package:proyect_movil/models/product_model.dart';
import 'package:proyect_movil/services/auth_service.dart';

class FavoritesService {
  final Dio _dio = AuthService().dio; 

  // Obtener lista de favoritos
  Future<List<Product>> getFavorites() async {
    try {
      final response = await _dio.get('/catalog/favorites/');
      
      // Ajustamos para leer 'results' si existe, o la lista directa
      final List<dynamic> data = (response.data is Map && response.data.containsKey('results')) 
          ? response.data['results'] 
          : response.data;

      return data.map((json) {
        // --- AQUÍ ESTÁ LA CORRECCIÓN CLAVE ---
        // Verificamos si el producto viene anidado en una propiedad 'product'
        // o 'products_product' (común en relaciones de Django/DB)
        if (json.containsKey('product') && json['product'] != null) {
           return Product.fromJson(json['product']);
        } 
        // Si por alguna razón viene plano (directo)
        else {
           return Product.fromJson(json);
        }
      }).toList();

    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  // Alternar favorito (Like/Dislike)
  Future<bool> toggleFavorite(int productId) async {
    try {
      final response = await _dio.post(
        '/catalog/favorites/toggle/',
        data: {'product_id': productId},
      );
      return response.data['is_favorite'] ?? false;
    } catch (e) {
      print('Error toggling favorite: $e');
      throw Exception('No se pudo actualizar favoritos');
    }
  }
}