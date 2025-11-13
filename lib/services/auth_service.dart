import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // --- INICIO DE CAMBIOS SINGLETON ---
  
  // 1. Instancia privada estática
  static final AuthService _instance = AuthService._internal();

  // 2. Factory constructor que devuelve la instancia
  factory AuthService() {
    return _instance;
  }

  // 3. Constructor interno privado
  AuthService._internal();

  // --- FIN DE CAMBIOS SINGLETON ---

  final Dio _dio = Dio(
    BaseOptions(
      // 4. Apunta a tu backend en Render
      baseUrl: 'https://smartsales365-backend.onrender.com/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  /// Método para hacer login y obtener el token JWT
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "/users/login/", // Endpoint de tu documentación
        data: {
          "email": email,
          "password": password,
        },
      );

      if (response.statusCode == 200 && response.data["access"] != null) {
        String accessToken = response.data["access"];
        String refreshToken = response.data["refresh"];
        await _saveTokens(accessToken, refreshToken);

        // 5. AÑADE EL TOKEN AL HEADER COMPARTIDO INMEDIATAMENTE
        await addTokenToHeader();

        return {
          'success': true,
          'access_token': accessToken,
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
        "/users/create/", // Asumiendo este endpoint
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

  /// Guarda los tokens localmente
  Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", access);
    await prefs.setString("refresh_token", refresh);
  }

  /// Obtiene el token guardado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  /// Agrega el token a los headers de futuras peticiones protegidas
  Future<void> addTokenToHeader() async {
    final token = await getToken();
    if (token != null) {
      _dio.options.headers["Authorization"] = "Bearer $token";
    }
  }

  /// Cierra sesión eliminando tokens
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    _dio.options.headers.remove("Authorization"); // Limpia el header
  }

  /// Método para acceder a Dio desde otros servicios, ya configurado
  Dio get dio => _dio;
}