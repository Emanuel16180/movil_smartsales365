// lib/models/product_model.dart

class Product {
  final int id;
  final String name;
  final String description;
  final String? size;
  final int stock;
  final double price;
  final String brand;
  final String imageUrl; // <-- Este es el culpable
  final int categoryId;
  final Map<String, dynamic> warranty;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.size,
    required this.stock,
    required this.price,
    required this.brand,
    required this.imageUrl,
    required this.categoryId,
    required this.warranty,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? 'Sin nombre', // Protección
      description: json['description'] ?? 'Sin descripción',
      size: json['size'],
      stock: json['stock'] ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      brand: json['brand'] != null && json['brand'] is Map ? (json['brand']['name'] ?? 'Sin Marca') : 'Sin Marca',
      // --- CORRECCIÓN CLAVE ---
      imageUrl: json['image_url'] ?? '', // Si es null, pone string vacío
      // -----------------------
      categoryId: json['category'] != null && json['category'] is Map ? (json['category']['id'] ?? 0) : 0,
      warranty: json['warranty'] ?? {},
    );
  }
}