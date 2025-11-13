// lib/models/category_model.dart
class Category {
  final int id;
  final String name;
  final String? description; // Hacemos la descripción opcional

  Category({
    required this.id,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'], // Puede ser null
    );
  }
}