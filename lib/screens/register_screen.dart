// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
// 1. IMPORTA LA PANTALLA DE NAVEGACIÓN PRINCIPAL
import 'app_navigation_screen.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // 2. CORRIGE EL WARNING DE TIPO PRIVADO
  RegisterScreenState createState() => RegisterScreenState();
}

// 3. CORRIGE EL WARNING DE TIPO PRIVADO
class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? errorMessage;
  bool _isLoading = false; // Añadido para feedback

  void register() async {
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    bool success = await _authService.register(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    // 4. CORRIGE EL WARNING DE 'BUILDCONTEXT'
    if (!mounted) return; 

    if (success) {
      // 5. NAVEGA A LA PANTALLA CORRECTA
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppNavigationScreen()),
      );
    } else {
      setState(() {
        errorMessage = "Error en el registro";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa el nuevo tema de la app
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Fondo gris claro
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Correo electrónico',
                prefixIcon: Icon(Icons.mail_outline, color: theme.colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary, // Azul
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Registrarse',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}