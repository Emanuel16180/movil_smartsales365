// lib/widgets/cart_body.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card; 
import 'package:provider/provider.dart';
import 'package:proyect_movil/services/sales_service.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';

class CartBody extends StatefulWidget {
  final bool showBack;
  final VoidCallback? onOrder;

  const CartBody({super.key, this.showBack = false, this.onOrder});

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  final SalesService _salesService = SalesService();
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    final cart = Provider.of<CartService>(context, listen: false);

    final cartItems = cart.items.map((item) {
      return {
        'product_id': item.product.id,
        'quantity': item.quantity,
      };
    }).toList();

    try {
      final response = await _salesService.createPaymentIntent(cartItems);

      if (response['success'] == false) {
        throw Exception(response['message']);
      }

      final clientSecret = response['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SmartSales365', 
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (!mounted) return;

      cart.clearCart(); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pago completado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // El usuario canceló
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de Stripe: ${e.error.localizedMessage}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    final theme = Theme.of(context); // <-- Obtenemos el tema

    return Column(
      children: [
        if (cart.items.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                "Tu carrito está vacío",
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10), // Añadimos padding
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final CartItem item = cart.items[index];
                return Card(
                  // --- ESTILO ACTUALIZADO ---
                  color: theme.cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  margin:
                      const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect( // <-- Para bordes redondeados
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        item.product.imageUrl, 
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    title: Text(item.product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold
                        )),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "Bs. ${item.product.price.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: theme.colorScheme.primary, // Azul
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: theme.colorScheme.primary,
                              onPressed: () {
                                cart.decreaseQuantity(item.product);
                              },
                            ),
                            Text(item.quantity.toString(), style: theme.textTheme.bodyLarge),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: theme.colorScheme.primary,
                              onPressed: () {
                                cart.increaseQuantity(item.product);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: theme.colorScheme.error.withAlpha(204),
                      onPressed: () {
                        cart.removeFromCart(item.product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text("${item.product.name} eliminado")),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
            color: theme.cardColor, // Fondo blanco
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total:", style: theme.textTheme.titleLarge),
                  Text(
                    "Bs. ${cart.total.toStringAsFixed(2)}",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (cart.items.isEmpty || _isLoading) ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary, // Azul
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Bordes
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
                    : const Text("Realizar pedido", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        )
      ],
    );
  }
}