import 'package:dio/dio.dart';
import '../models/product_model.dart';
import '../models/product_response_model.dart';
import 'auth_service.dart'; // <-- 1. Importa el AuthService

class ProductService {
  // 2. Usa la instancia de Dio compartida
  final Dio _dio = AuthService().dio;

  Future<ProductListResponse> fetchProducts({
    String? url,
    int? categoryId,
    String? search,
  }) async {
    try {
      String endpoint = url ?? '/catalog/products/';
      
      Map<String, dynamic> queryParams = {};
      if (url == null) { 
        if (categoryId != null) {
          queryParams['category'] = categoryId;
        }
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search; 
        }
      }

      // 3. La llamada ya usa el Dio autenticado
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        final String? nextUrl = response.data['next'];

        List<Product> products = results
            .map((json) => Product.fromJson(json))
            .toList();
        
        return ProductListResponse(products: products, nextUrl: nextUrl);
      } else {
        throw Exception('Error al cargar productos');
      }
    } catch (e) {
      print('Error en ProductService: $e');
      throw Exception('Error al conectar con la API: $e');
    }
  }
}