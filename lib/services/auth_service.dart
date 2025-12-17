import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // --- SINGLETON SETUP ---
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();
  // -----------------------

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://backend-smartsales365.onrender.com/api/v1',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  /// Método para hacer login y obtener el token JWT + ROL
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "/users/login/", 
        data: {
          "email": email,
          "password": password,
        },
      );

      if (response.statusCode == 200 && response.data["access"] != null) {
        String accessToken = response.data["access"];
        String refreshToken = response.data["refresh"];
        
        // --- NUEVO: CAPTURA DEL ROL ---
        // Buscamos el rol en la respuesta del backend. 
        // Si no viene, asumimos 'CUSTOMER' por defecto.
        String role = 'CUSTOMER'; 
        if (response.data['user'] != null && response.data['user']['role'] != null) {
          role = response.data['user']['role'];
        }

        // Guardamos tokens Y el rol
        await _saveTokens(accessToken, refreshToken, role);
        await addTokenToHeader();

        return {
          'success': true,
          'access_token': accessToken,
          'role': role, // Devolvemos el rol para que la UI sepa a dónde ir
        };
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Credenciales incorrectas',
        };
      }
      return {
        'success': false,
        'message': 'Error de conexión: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
    return {
      'success': false,
      'message': 'Error desconocido en el login.',
    };
  }

  /// Método para registrar usuario
  Future<bool> register(String email, String password) async {
    try {
      Response response = await _dio.post(
        "/users/create/", 
        data: {
          "email": email,
          "password": password,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error en registro: $e");
      return false;
    }
  }

  /// Guarda los tokens y el rol localmente
  Future<void> _saveTokens(String access, String refresh, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", access);
    await prefs.setString("refresh_token", refresh);
    await prefs.setString("user_role", role); // <--- NUEVO: Guardamos el rol
  }

  /// Obtiene el token guardado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  /// Obtiene el rol guardado (útil para verificar sesión al reiniciar app)
  Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_role") ?? 'CUSTOMER';
  }

  /// Agrega el token a los headers de futuras peticiones protegidas
  Future<void> addTokenToHeader() async {
    final token = await getToken();
    if (token != null) {
      _dio.options.headers["Authorization"] = "Bearer $token";
    }
  }

  /// Cierra sesión eliminando tokens y rol
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    await prefs.remove("user_role"); // <--- Limpiamos el rol
    _dio.options.headers.remove("Authorization"); 
  }

  /// Método para acceder a Dio desde otros servicios
  Dio get dio => _dio;
}