// lib/widgets/cart_body.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card; 
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart'; 
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
  final TextEditingController _couponController = TextEditingController();
  
  // Variables de Delivery
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  bool _isDelivery = false; 
  Position? _gpsLocation;   
  bool _isLoadingLocation = false; 
  bool _isLoadingPayment = false;

  @override
  void dispose() {
    _couponController.dispose();
    _addressController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('El GPS está desactivado.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permiso denegado.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Permisos denegados permanentemente.');

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );

      setState(() {
        _gpsLocation = position;
        _isLoadingLocation = false;
      });

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Ubicación guardada! ✅"), backgroundColor: Colors.green));

    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _handlePayment() async {
    if (_isDelivery) {
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Escribe una dirección")));
        return;
      }
      if (_gpsLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Presiona 'Obtener mi Ubicación'")));
        return;
      }
    }

    setState(() => _isLoadingPayment = true);
    final cart = Provider.of<CartService>(context, listen: false);
    
    // Payload
    final cartItems = cart.items.map((item) => {'product_id': item.product.id, 'quantity': item.quantity}).toList();
    Map<String, dynamic>? deliveryInfo;
    if (_isDelivery && _gpsLocation != null) {
      deliveryInfo = {
        "address": _addressController.text.trim(),
        "description": _refController.text.trim(),
        "latitude": _gpsLocation!.latitude,
        "longitude": _gpsLocation!.longitude,
      };
    }

    try {
      final response = await _salesService.createPaymentIntent(
        cartItems, 
        couponCode: cart.couponCode,
        deliveryInfo: deliveryInfo,
      );

      if (response['success'] == false) throw Exception(response['message']);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: response['clientSecret'],
          merchantDisplayName: 'SmartSales365', 
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (!mounted) return;
      cart.clearCart(); 
      _cleanForm();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Pago exitoso!'), backgroundColor: Colors.green));
      
    } on StripeException catch (e) {
      if (e.error.code != FailureCode.Canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Stripe: ${e.error.localizedMessage}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoadingPayment = false);
    }
  }

  void _cleanForm() {
    _couponController.clear();
    _addressController.clear();
    _refController.clear();
    setState(() { _isDelivery = false; _gpsLocation = null; });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    final theme = Theme.of(context);

    if (cart.items.isEmpty) {
      return Center(child: Text("Tu carrito está vacío", style: TextStyle(color: Colors.grey[600], fontSize: 18)));
    }

    // --- DISEÑO SEGURO: UN SOLO LISTVIEW ---
    // Esto evita que el teclado rompa la pantalla
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      // Cantidad de items + 1 (para el footer gigante)
      itemCount: cart.items.length + 1,
      itemBuilder: (context, index) {
        
        // A. SI ES UN PRODUCTO
        if (index < cart.items.length) {
          final CartItem item = cart.items[index];
          return Card(
            color: theme.cardColor,
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(item.product.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.broken_image)),
              ),
              title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bs. ${item.product.price.toStringAsFixed(2)}", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.decreaseQuantity(item.product)),
                      Text(item.quantity.toString()),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.increaseQuantity(item.product)),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => cart.removeFromCart(item.product)),
            ),
          );
        } 
        
        // B. SI ES EL FOOTER (CUPÓN + DELIVERY + PAGO)
        else {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. CUPÓN
                Row(
                  children: [
                    Expanded(child: TextField(controller: _couponController, decoration: const InputDecoration(hintText: 'Cupón', border: OutlineInputBorder()), enabled: !cart.isCouponApplied)),
                    const SizedBox(width: 8),
                    if (cart.isCouponApplied)
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { cart.removeCoupon(); _couponController.clear(); })
                    else
                      ElevatedButton(onPressed: () async {
                        if(_couponController.text.isEmpty) return;
                        try { await cart.applyCoupon(_couponController.text.trim()); } catch(e) { /* Error manejado en UI */ }
                      }, child: const Text("Aplicar")),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),

                // 2. SWITCH DELIVERY
                SwitchListTile(
                  title: const Text("Envío a Domicilio", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_isDelivery ? "Llenar datos" : "Recoger en tienda"),
                  value: _isDelivery,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) => setState(() { _isDelivery = v; if(!v) _gpsLocation = null; }),
                ),

                // 3. FORMULARIO DELIVERY (Condicional)
                if (_isDelivery) ...[
                  TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Dirección", icon: Icon(Icons.home))),
                  TextField(controller: _refController, decoration: const InputDecoration(labelText: "Referencia", icon: Icon(Icons.map))),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getLocation,
                    icon: _isLoadingLocation ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_gpsLocation != null ? Icons.check : Icons.gps_fixed),
                    label: Text(_gpsLocation != null ? "Ubicación OK" : "Obtener Ubicación"),
                    style: ElevatedButton.styleFrom(backgroundColor: _gpsLocation != null ? Colors.green : Colors.grey[800], foregroundColor: Colors.white),
                  ),
                  const Divider(),
                ],

                // 4. TOTALES
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Subtotal:"), Text("Bs. ${cart.subtotal.toStringAsFixed(2)}")
                ]),
                if (cart.isCouponApplied)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Descuento (${cart.couponCode}):", style: const TextStyle(color: Colors.green)),
                    Text("- Bs. ${cart.discountAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ]),
                const SizedBox(height: 5),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Bs. ${cart.total.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                ]),

                // 5. PAGAR
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoadingPayment ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoadingPayment ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("PAGAR AHORA", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}