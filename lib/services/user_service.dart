// lib/services/user_service.dart
import 'package:dio/dio.dart';
import 'package:proyect_movil/services/auth_service.dart'; // Para usar el Dio autenticado
import 'package:proyect_movil/models/user_model.dart';

class UserService {
  // Usamos la instancia de Dio que ya tiene el token de AuthService
  final Dio _dio = AuthService().dio; 

  /// Obtiene el perfil del usuario autenticado
  Future<UserModel> getUserProfile() async {
    try {
      final response = await _dio.get('/users/me/');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error fetching user profile: $e');
      throw Exception('No se pudo cargar el perfil: ${e.message}');
    }
  }

  /// Actualiza el perfil del usuario autenticado
  Future<UserModel> updateUserProfile(Map<String, dynamic> data) async {
    try {
      // Usamos PATCH como en tu documentación de ejemplo
      final response = await _dio.patch('/users/me/', data: data); 
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error updating user profile: $e');
      throw Exception('No se pudo actualizar el perfil: ${e.response?.data['error'] ?? e.message}');
    }
  }
}