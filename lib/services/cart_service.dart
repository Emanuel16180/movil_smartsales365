// lib/services/cart_service.dart
// Servicio singleton que mantiene el estado del carrito en memoria y lo comparte globalmente en la app
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();

  factory CartService() => _instance;

  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  //Agrega producto o suma cantidad si ya está
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

//Elimina el producto completamente del carrito
  void removeFromCart(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);
    saveCartToLocalStorage();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    saveCartToLocalStorage();
    notifyListeners();
  }

  double get total {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  //guardar en el carito
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
                'image_url': item.product.imageUrl, // <-- CAMBIO AQUÍ
                'stock': item.product.stock,
                'size': item.product.size,
                'category': item.product.categoryId,
                'warranty': item.product.warranty, // <-- CAMBIO AQUÍ
              },
              'quantity': item.quantity
            })
        .toList();

    await prefs.setString('cart', jsonEncode(cartData));
  }

//cargar en el carrito
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
            imageUrl: productData['image_url'], // <-- CAMBIO AQUÍ
            stock: productData['stock'],
            size: productData['size'],
            categoryId: productData['category'],
            warranty: productData['warranty'], // <-- CAMBIO AQUÍ
          ),
          quantity: entry['quantity'],
        );
      }));
      notifyListeners();
    }
  }
}