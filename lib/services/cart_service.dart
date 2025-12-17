// lib/services/cart_service.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import 'package:proyect_movil/services/sales_service.dart'; // Importar SalesService

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];
  final SalesService _salesService = SalesService(); // Instancia para validar

  // VARIABLES DE CUPÓN
  String? _appliedCouponCode;
  double _discountAmount = 0.0;
  bool _isCouponApplied = false;

  // GETTERS
  List<CartItem> get items => _items;
  String? get couponCode => _appliedCouponCode;
  bool get isCouponApplied => _isCouponApplied;
  double get discountAmount => _discountAmount;

  // Subtotal (Suma de productos)
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Total Final (Subtotal - Descuento)
  double get total {
    double t = subtotal - _discountAmount;
    return t < 0 ? 0.0 : t;
  }

  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // --- MÉTODOS DE CUPÓN ---
  Future<void> applyCoupon(String code) async {
    try {
      final result = await _salesService.validateCoupon(code);
      if (result['valid'] == true) {
        _appliedCouponCode = result['code'];
        _discountAmount = double.parse(result['discount'].toString());
        _isCouponApplied = true;
        notifyListeners();
      }
    } catch (e) {
      removeCoupon(); // Si falla, limpiamos
      rethrow;
    }
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _discountAmount = 0.0;
    _isCouponApplied = false;
    notifyListeners();
  }
  // ------------------------

  void addToCart(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(product: product));
    }
    saveCartToLocalStorage();
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);
    saveCartToLocalStorage();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    removeCoupon(); // Limpiamos el cupón al vaciar carrito
    saveCartToLocalStorage();
    notifyListeners();
  }

  void increaseQuantity(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_items[index].quantity < product.stock) {
        _items[index].quantity += 1;
        saveCartToLocalStorage();
        notifyListeners();
      }
    }
  }

  void decreaseQuantity(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
        saveCartToLocalStorage();
        notifyListeners();
      } else {
        removeFromCart(product);
      }
    }
  }

  Future<void> saveCartToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = _items
        .map((item) => {
              'product': {
                'id': item.product.id,
                'name': item.product.name,
                'description': item.product.description,
                'price': item.product.price,
                'brand': item.product.brand,
                'image_url': item.product.imageUrl,
                'stock': item.product.stock,
                'size': item.product.size,
                'category': item.product.categoryId,
                'warranty': item.product.warranty,
              },
              'quantity': item.quantity
            })
        .toList();

    await prefs.setString('cart', jsonEncode(cartData));
  }

  Future<void> loadCartFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart');

    if (cartString != null) {
      final List<dynamic> cartJson = jsonDecode(cartString);
      _items.clear();
      _items.addAll(cartJson.map((entry) {
        final productData = entry['product'];
        return CartItem(
          product: Product(
            id: productData['id'],
            name: productData['name'],
            description: productData['description'],
            price: (productData['price'] as num).toDouble(),
            brand: productData['brand'],
            imageUrl: productData['image_url'],
            stock: productData['stock'],
            size: productData['size'],
            categoryId: productData['category'],
            warranty: productData['warranty'],
          ),
          quantity: entry['quantity'],
        );
      }));
      notifyListeners();
    }
  }
}