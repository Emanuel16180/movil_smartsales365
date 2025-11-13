// lib/models/paginated_response.dart
class PaginatedResponse<T> {
  final List<T> results;
  final String? nextUrl;

  PaginatedResponse({required this.results, this.nextUrl});
}