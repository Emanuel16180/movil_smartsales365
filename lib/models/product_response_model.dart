import 'package:proyect_movil/models/product_model.dart';

class ProductListResponse {
  final List<Product> products;
  final String? nextUrl;

  ProductListResponse({required this.products, this.nextUrl});
}