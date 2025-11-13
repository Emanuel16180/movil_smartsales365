import 'package:flutter/material.dart';
// ¡Esta línea es la clave para arreglar el error de 'Card' de tu última foto!
import 'package:flutter_stripe/flutter_stripe.dart' hide Card; 
import 'package:provider/provider.dart';
import 'package:proyect_movil/services/sales_service.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';

// 1. Convertido a StatefulWidget para manejar el estado de carga
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

  // 2. Lógica de pago de Stripe
  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    final cart = Provider.of<CartService>(context, listen: false);

    // Formatea el carrito como lo pide tu API
    final cartItems = cart.items.map((item) {
      return {
        'product_id': item.product.id,
        'quantity': item.quantity,
      };
    }).toList();

    try {
      // --- PASO 1: Crear Payment Intent en tu Backend ---
      final response = await _salesService.createPaymentIntent(cartItems);

      if (response['success'] == false) {
        throw Exception(response['message']);
      }

      final clientSecret = response['clientSecret'];

      // --- PASO 2: Inicializar la Hoja de Pago de Stripe ---
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SmartSales365', // El nombre de tu tienda
        ),
      );

      // --- PASO 3: Mostrar la Hoja de Pago ---
      await Stripe.instance.presentPaymentSheet();

      // --- PASO 4: Éxito ---
      cart.clearCart(); // Limpia el carrito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pago completado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // El usuario canceló la hoja de pago
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de Stripe: ${e.error.localizedMessage}')),
        );
      }
    } catch (e) {
      // Muestra errores de tu backend (ej. stock insuficiente)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);

    return Column(
      children: [
        if (cart.items.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                "Tu carrito está vacío",
                style: TextStyle(color: Color(0xFF8B1E3F)),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final CartItem item = cart.items[index];
                // Esto es un Flutter Card (Material)
                return Card(
                  color: const Color(0xFFFDEAEA),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Image.network(
                      item.product.imageUrl, // Usa el campo 'imageUrl'
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                    title: Text(item.product.name,
                        style: const TextStyle(color: Color(0xFF8B1E3F))),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bs. ${item.product.price.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.black87),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              color: const Color(0xFF8B1E3F),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  item.quantity--;
                                  cart.saveCartToLocalStorage();
                                  cart.notifyListeners();
                                }
                              },
                            ),
                            Text(item.quantity.toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              color: const Color(0xFF8B1E3F),
                              onPressed: () {
                                if (item.quantity < item.product.stock) {
                                  item.quantity++;
                                  cart.saveCartToLocalStorage();
                                  cart.notifyListeners();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red[300],
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
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black12)),
            color: Color(0xFFF8E8E8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Subtotal:", style: TextStyle(fontSize: 18)),
                  Text(
                    "Bs. ${cart.total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF8B1E3F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                // Esto llama a la nueva función de Stripe
                onPressed: (cart.items.isEmpty || _isLoading) ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
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
                    : const Text("Realizar pedido"),
              ),
            ],
          ),
        )
      ],
    );
  }
}