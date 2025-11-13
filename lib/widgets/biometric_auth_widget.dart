// lib/screens/widgets/biometric_auth_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BiometricAuthWidget extends StatelessWidget {
  final VoidCallback onBiometricSuccess;
  final bool isVisible;

  const BiometricAuthWidget({
    Key? key,
    required this.onBiometricSuccess,
    this.isVisible = true,
  }) : super(key: key);

  Future<void> _authenticate(BuildContext context) async {
    // --- AQUÍ IRÍA LA LÓGICA REAL DE BIOMETRÍA ---
    // (Usando local_auth, etc.)
    // Por ahora, solo simulamos el éxito como en tu ejemplo.
    
    // Simulación de éxito:
    onBiometricSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Usamos AnimatedOpacity para un efecto de aparición suave
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: isVisible ? 1.0 : 0.0,
      child: isVisible
          ? Column(
              children: [
                SizedBox(height: 4.h),
                Text(
                  'O usa tu huella dactilar',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 2.h),
                IconButton(
                  icon: Icon(
                    Icons.fingerprint,
                    size: 10.w,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => _authenticate(context),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}