// lib/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:proyect_movil/screens/cart_modal_screen.dart';
import '../models/product_model.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xFFF8E8E8), // Fondo bordó claro
      appBar: AppBar(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF8B1E3F), // Bordó oscuro
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Imagen (usando el nuevo campo imageUrl)
            AspectRatio(
              aspectRatio: 1.5,
              child: Image.network(
                product.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 2. Precio
                  Text(
                    "Bs. ${product.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Color(0xFF8B1E3F), // Precio en color bordó
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 3. Marca (usando el nuevo campo aplanado)
                  Text(
                    "Marca: ${product.brand}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Selector de Cantidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text("Cantidad:", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF8B1E3F),
                      ),
                      Text(quantity.toString(),
                          style: const TextStyle(fontSize: 18)),
                      IconButton(
                        onPressed: () {
                          if (quantity < product.stock) {
                            setState(() {
                              quantity++;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stock máximo alcanzado'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF8B1E3F),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "(${product.stock} en stock)",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 5. Descripción
                  const Text(
                    "Descripción:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  // 6. Garantía (usando el objeto warranty)
                  const Text(
                    "Garantía:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${product.warranty['title'] ?? 'No especificada'} (${product.warranty['duration_days'] ?? 0} días)",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    product.warranty['terms'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),

                  const SizedBox(height: 30),

                  // Botón de Agregar al carrito
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: product.stock > 0 ? () {
                        final cart = Provider.of<CartService>(context, listen: false);
                        
                        // Lógica para no agregar más del stock
                        final itemEnCarrito = cart.items.firstWhere(
                          (item) => item.product.id == product.id,
                          orElse: () => CartItem(product: product, quantity: 0),
                        );
                        final cantidadActual = itemEnCarrito.quantity;

                        if (cantidadActual + quantity > product.stock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No puedes agregar más del stock disponible (${product.stock})')),
                          );
                          return;
                        }

                        // Agrega al carrito
                        for (int i = 0; i < quantity; i++) {
                          cart.addToCart(product);
                        }
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => const CartModalScreen(),
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '$quantity ${product.name} agregado(s) al carrito')),
                        );
                      }
                      : null, // Deshabilita el botón si no hay stock
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E3F),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        product.stock > 0 ? "Agregar al carrito" : "Sin Stock",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30), // Espacio extra
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}