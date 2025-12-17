// lib/services/delivery_service.dart
import 'package:dio/dio.dart';
import 'package:proyect_movil/services/auth_service.dart';

class DeliveryService {
  final Dio _dio = AuthService().dio;

  // Obtener lista de entregas (Resumen)
  Future<List<dynamic>> getMyDeliveries() async {
    try {
      final response = await _dio.get('/sales/deliveries/');
      if (response.data is List) return response.data;
      if (response.data['results'] != null) return response.data['results'];
      return [];
    } catch (e) {
      throw Exception('Error al cargar entregas: $e');
    }
  }

  // --- NUEVO: Obtener detalle completo de UN pedido ---
  Future<Map<String, dynamic>> getDeliveryDetails(int id) async {
    try {
      // Endpoint sugerido: /api/v1/sales/deliveries/123/
      final response = await _dio.get('/sales/deliveries/$id/');
      return response.data;
    } catch (e) {
      throw Exception('Error al cargar detalles: $e');
    }
  }

  // --- ACTUALIZADO: Cambiar a cualquier estado ---
  // status puede ser: 'IN_TRANSIT' o 'DELIVERED'
  Future<bool> updateDeliveryStatus(int deliveryId, String newStatus) async {
    try {
      final response = await _dio.patch(
        '/sales/deliveries/$deliveryId/update-status/',
        data: {'status': newStatus},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error actualizando estado: $e");
      return false;
    }
  }
}