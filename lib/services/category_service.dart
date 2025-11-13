import 'package:dio/dio.dart';
import '../models/category_model.dart';
import 'auth_service.dart'; // <-- 1. Importa el AuthService

class CategoryService {
  // 2. Usa la instancia de Dio compartida
  final Dio _dio = AuthService().dio;

  Future<List<Category>> fetchCategories() async {
    try {
      // 3. Llama al endpoint de tu API
      final response = await _dio.get('/catalog/categories/');
      
      if (response.statusCode == 200) {
        // 4. Asume paginación y lee de 'results'
        List<Category> categories = (response.data['results'] as List)
            .map((json) => Category.fromJson(json))
            .toList();
        return categories;
      } else {
        throw Exception('Error al cargar categorías');
      }
    } catch (e) {
      print('Error en CategoryService: $e'); // Añadido para depuración
      throw Exception('Error al conectar con la API: $e');
    }
  }
}