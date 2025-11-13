import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  CardFieldInputDetails? _card;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con tarjeta'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Ingrese los datos de su tarjeta'),
            const SizedBox(height: 20),

            // Widget de Stripe para ingresar datos de la tarjeta
            CardField(
              onCardChanged: (card) {
                setState(() {
                  _card = card;
                });
              },
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _card?.complete == true ? _handlePayment : null,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Pagar'),
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _handlePayment() async {
  setState(() => _loading = true);

  try {
    // PASO 1: Crear PaymentIntent en el backend
    final dio = Dio();
    final response = await dio.post(
      'http://192.168.0.5:8000/api/create-payment-intent/',
      data: {'amount': 10000}, // Bs. 100.00 (usar centavos)
    );

    final clientSecret = response.data['client_secret'];

    // PASO 2: Confirmar el pago con Stripe
    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: PaymentMethodParams.card(
        paymentMethodData: const PaymentMethodData(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pago realizado exitosamente')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al pagar: $e')),
    );
  } finally {
    setState(() => _loading = false);
  }
}

}
