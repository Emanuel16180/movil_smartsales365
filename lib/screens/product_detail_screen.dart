// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart'; // Importe necesario para 'SizedBox(width: 3.w)'
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../screens/cart_modal_screen.dart'; // Para abrir el carrito modal
import 'package:proyect_movil/providers/favorites_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  // --- ESTOS MÉTODOS AHORA SÍ SE USARÁN ---
  void _increaseQuantity() {
    setState(() {
      if (_quantity < widget.product.stock) {
        _quantity++;
      }
    });
  }

  void _decreaseQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
  }

  void _addToCart() {
    final cart = Provider.of<CartService>(context, listen: false);
    for (int i = 0; i < _quantity; i++) {
      cart.addToCart(widget.product);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_quantity x ${widget.product.name} añadido al carrito.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  // --- FIN DE MÉTODOS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartService = Provider.of<CartService>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFav = favoritesProvider.isFavorite(widget.product.id);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Fondo gris claro
      extendBodyBehindAppBar: true, // Para que la imagen quede detrás del AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar transparente
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(102), // Corregido de withOpacity
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border, 
                color: isFav ? Colors.red : Colors.white
              ),
              onPressed: () {
                favoritesProvider.toggleFavorite(widget.product);
              },
            ),
          ),
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(102), // Corregido de withOpacity
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => const CartModalScreen(),
                      ),
                    );
                  },
                ),
              ),
              if (cartService.totalItems > 0) // Corregido a totalItems
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '${cartService.totalItems}', // Corregido a totalItems
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      // --- ¡EL BODY QUE FALTABA! ---
      body: Column(
        children: [
          // Sección de imagen (ocupa 40% de la pantalla)
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, size: 100, color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
          // Sección de detalles del producto (ocupa 60% de la pantalla)
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor, // Fondo blanco para los detalles
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13), // ~0.05 opacity
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del producto
                  Text(
                    widget.product.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Precio y stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Bs. ${widget.product.price.toStringAsFixed(2)}",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.product.stock > 0 ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26), // ~0.1 opacity
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.product.stock > 0 ? 'En Stock: ${widget.product.stock}' : 'Sin Stock',
                          style: TextStyle(
                            color: widget.product.stock > 0 ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Descripción y Garantía
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. SECCIÓN DE DESCRIPCIÓN
                          Text(
                            'Descripción',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          
                          // 2. SECCIÓN DE GARANTÍA
                          const SizedBox(height: 20),
                          Text(
                            'Garantía',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${widget.product.warranty['title'] ?? 'No especificada'} (${widget.product.warranty['duration_days'] ?? 0} días)",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.product.warranty['terms'] ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Selector de cantidad y botón de añadir al carrito
                  Row(
                    children: [
                      // Selector de cantidad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: theme.colorScheme.primary, size: 20),
                              onPressed: _decreaseQuantity, // <-- Ahora se usa
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                _quantity.toString(),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: theme.colorScheme.primary, size: 20),
                              onPressed: _increaseQuantity, // <-- Ahora se usa
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 3.w), // <-- Ahora Sizer se usa
                      // Botón Añadir al Carrito
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.product.stock > 0 ? _addToCart : null, // <-- Ahora se usa
                          icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                          label: Text(
                            widget.product.stock > 0 ? 'Añadir al Carrito' : 'Sin Stock',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}