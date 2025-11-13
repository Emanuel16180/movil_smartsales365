// lib/models/product_model.dart

class Product {
  final int id;
  final String name;
  final String description;
  final String? size; // El size puede no venir
  final int stock;
  final double price;
  final String brand; // Lo aplanamos a String
  final String imageUrl; // Cambiamos de 'image' a 'imageUrl'
  final int categoryId; // Solo guardamos el ID
  final Map<String, dynamic> warranty; // Guardamos el objeto de garantía

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

  // Factory para crear un Producto desde tu nuevo JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? 'Sin descripción',
      size: json['size'], // Asumimos que 'size' puede no estar
      stock: json['stock'] ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      // Leemos el nombre desde el objeto anidado
      brand: json['brand']?['name'] ?? 'Sin Marca', 
      // Leemos la URL de la imagen
      imageUrl: json['image_url'] ?? '', 
      // Leemos el ID desde el objeto anidado
      categoryId: json['category']?['id'] ?? 0, 
      warranty: json['warranty'] ?? {}, // Guardamos el objeto completo
    );
  }
}