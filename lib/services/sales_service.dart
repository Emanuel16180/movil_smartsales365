import 'package:dio/dio.dart';
import 'package:proyect_movil/services/auth_service.dart';
import 'package:proyect_movil/models/purchase_model.dart';
import 'package:proyect_movil/models/warranty_model.dart';
import 'package:proyect_movil/models/paginated_response.dart';

class SalesService {
  final Dio _dio = AuthService().dio; // Usa el Dio Singleton

  // --- NUEVA FUNCIÓN PARA CREAR EL INTENTO DE PAGO ---
  Future<Map<String, dynamic>> createPaymentIntent(List<Map<String, dynamic>> cartItems) async {
    try {
      final response = await _dio.post(
        '/sales/create-payment-intent/',
        data: {
          'cart': cartItems, // Envía el carrito en el formato que tu API espera
        },
      );
      
      // Devuelve éxito y el clientSecret
      return {'success': true, 'clientSecret': response.data['clientSecret']};

    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Error de stock o carrito inválido
        return {'success': false, 'message': e.response?.data['error'] ?? 'Stock insuficiente o error en el carrito.'};
      }
      return {'success': false, 'message': 'Error al crear intento de pago: ${e.response?.data}'};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // --- FUNCIONES EXISTENTES (MIS COMPRAS Y GARANTÍAS) ---

  Future<PaginatedResponse<Purchase>> getMyPurchases({String? url}) async {
    String endpoint = url ?? '/sales/my-purchases/';
    try {
      final response = await _dio.get(endpoint);
      final List<dynamic> results = response.data['results'];
      final String? nextUrl = response.data['next'];
      List<Purchase> purchases = results.map((data) => Purchase.fromJson(data)).toList();
      return PaginatedResponse(results: purchases, nextUrl: nextUrl);
    } catch (e) {
      print('Error fetching purchases: $e');
      throw Exception('Failed to load purchases');
    }
  }

  Future<PaginatedResponse<Warranty>> getMyWarranties({String? url}) async {
    String endpoint = url ?? '/sales/my-warranties/';
    try {
      final response = await _dio.get(endpoint);
      final List<dynamic> results = response.data['results'];
      final String? nextUrl = response.data['next'];
      List<Warranty> warranties = results.map((data) => Warranty.fromJson(data)).toList();
      return PaginatedResponse(results: warranties, nextUrl: nextUrl);
    } catch (e) {
      print('Error fetching warranties: $e');
      throw Exception('Failed to load warranties');
    }
  }

  Future<Map<String, dynamic>> getPurchaseReceipt(int purchaseId) async {
    try {
      final response = await _dio.get('/sales/receipt/$purchaseId/');
      return response.data;
    } on DioException catch (e) {
      print('Error fetching receipt $purchaseId: $e');
      if (e.response?.statusCode == 404) {
        throw Exception('Recibo no encontrado.');
      }
      throw Exception('Failed to load receipt');
    }
  }
}