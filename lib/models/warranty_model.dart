// lib/models/warranty_model.dart
class Warranty {
  final int productId;
  final String productName;
  final String imageUrl;
  final String startDate;
  final String expirationDate;

  Warranty({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.startDate,
    required this.expirationDate,
  });

  factory Warranty.fromJson(Map<String, dynamic> json) {
    return Warranty(
      productId: json['product']?['id'] ?? 0,
      productName: json['product']?['name'] ?? 'Producto no encontrado',
      imageUrl: json['product']?['image_url'] ?? '',
      startDate: json['start_date'],
      expirationDate: json['expiration_date'],
    );
  }
}