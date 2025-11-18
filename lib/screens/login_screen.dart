// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:proyect_movil/services/auth_service.dart';
import 'package:proyect_movil/screens/app_navigation_screen.dart';
import 'package:proyect_movil/screens/register_screen.dart';

// Importa los widgets de UI
import 'package:proyect_movil/widgets/logo_widget.dart';
import 'package:proyect_movil/widgets/login_form_widget.dart';

// Importa los servicios para la lógica de notificación
import 'package:proyect_movil/services/notification_service.dart';
import 'package:proyect_movil/services/sales_service.dart';
import 'package:proyect_movil/models/warranty_model.dart';
import 'package:proyect_movil/models/paginated_response.dart'; // Necesario para manejar la respuesta paginada

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- MÉTODO CORREGIDO: Revisa TODAS las páginas de garantías ---
  Future<void> _checkNextWarranty() async {
    print("🔍 [DEBUG] Iniciando chequeo de garantías (REVISIÓN COMPLETA)...");
    try {
      final salesService = SalesService();
      final notificationService = NotificationService();
      
      Warranty? nextExpiring;
      Duration? smallestDifference;
      
      String? nextUrl; // Variable para guardar la URL de la siguiente página
      bool keepFetching = true;
      int pageCount = 1;

      final DateTime now = DateTime.now();
      // Normalizamos "hoy" para comparar solo fechas (sin hora)
      final DateTime today = DateTime(now.year, now.month, now.day);

      // Bucle para recorrer todas las páginas disponibles
      while (keepFetching) {
        print("📄 [DEBUG] Revisando página $pageCount...");
        
        // Pedimos garantías (si nextUrl es null, pide la primera página)
        final PaginatedResponse<Warranty> response = await salesService.getMyWarranties(url: nextUrl);
        final List<Warranty> warranties = response.results;
        
        // Actualizamos la URL para la siguiente vuelta del bucle
        nextUrl = response.nextUrl;

        // Revisamos las garantías de esta página
        for (var w in warranties) {
          final DateTime? expDate = DateTime.tryParse(w.expirationDate);
          
          if (expDate != null) {
            final DateTime expDay = DateTime(expDate.year, expDate.month, expDate.day);
            
            // Si la garantía NO ha vencido (es hoy o futuro)
            if (!expDay.isBefore(today)) {
              final difference = expDay.difference(today);
              
              // Buscamos la que vence más pronto de todas las encontradas hasta ahora
              if (smallestDifference == null || difference < smallestDifference) {
                smallestDifference = difference;
                nextExpiring = w;
              }
            }
          }
        }

        // Si nextUrl es null, significa que ya no hay más páginas que revisar
        if (nextUrl == null) {
          keepFetching = false;
        } else {
          pageCount++;
        }
      }

      // --- RESULTADO FINAL ---
      if (nextExpiring != null) {
        String bodyMsg;
        if (smallestDifference!.inDays == 0) {
          bodyMsg = "¡La garantía de '${nextExpiring.productName}' vence HOY!";
        } else {
          bodyMsg = "La garantía de '${nextExpiring.productName}' vence en ${smallestDifference.inDays} días.";
        }

        print("✅ [DEBUG] ¡ENCONTRADA! Enviando notificación: $bodyMsg");
        await notificationService.showNotification(
          "Recordatorio de Garantía",
          bodyMsg,
        );
      } else {
        print("⚠️ [DEBUG] Se revisaron todas las páginas y no hay garantías activas próximas a vencer.");
      }

    } catch (e) {
      print("🔥 [DEBUG] Error fatal en notificación: $e");
    }
  }
  // -------------------------------------------------------------

  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        email.trim(),
        password.trim(),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        HapticFeedback.lightImpact();
        
        // --- ¡AQUÍ LLAMAMOS A LA NOTIFICACIÓN! ---
        // No usamos 'await' aquí para que la navegación sea rápida y la búsqueda se haga en segundo plano
        _checkNextWarranty(); 
        // -----------------------------------------
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Bienvenido/a!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const AppNavigationScreen()),
        );
      } else {
        _showErrorMessage(
            response['message'] ?? 'Error desconocido. Intente de nuevo.');
      }
    } catch (e) {
      _showErrorMessage('Error de conexión. Verifica tu conexión a internet.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showErrorMessage(String message) {
    if (mounted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 8.h),

                  // 1. Logo
                  const LogoWidget(),
                  SizedBox(height: 6.h),

                  // 2. Formulario de Login
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 90.w),
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(4.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Iniciar Sesión',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Accede a tu cuenta SmartSales365',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                        SizedBox(height: 4.h),
                        
                        LoginFormWidget(
                          onLogin: _handleLogin,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 4.h), 

                  // 3. Link de Registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Nuevo usuario? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _navigateToRegistration,
                        child: Text(
                          'Crear Cuenta',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}