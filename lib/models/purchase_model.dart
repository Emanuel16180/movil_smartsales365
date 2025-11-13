// lib/models/purchase_model.dart
class Purchase {
  final int id;
  final String totalAmount;
  final String status;
  final String createdAt;
  final int itemCount;

  Purchase({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.itemCount,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      totalAmount: json['total_amount'],
      status: json['status'],
      createdAt: json['created_at'],
      itemCount: json['item_count'],
    );
  }
}