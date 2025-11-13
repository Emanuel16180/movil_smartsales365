// lib/screens/garantias_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyect_movil/models/warranty_model.dart';
import 'package:proyect_movil/models/paginated_response.dart';
import 'package:proyect_movil/services/sales_service.dart';

class GarantiasScreen extends StatefulWidget {
  const GarantiasScreen({super.key});

  @override
  State<GarantiasScreen> createState() => _GarantiasScreenState();
}

class _GarantiasScreenState extends State<GarantiasScreen> {
  final SalesService _salesService = SalesService();
  final ScrollController _scrollController = ScrollController();
  List<Warranty> _warranties = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _nextPageUrl;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _loadMoreWarranties();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchWarranties() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final PaginatedResponse<Warranty> response =
          await _salesService.getMyWarranties();
      if (mounted) {
        setState(() {
          _warranties = response.results;
          _nextPageUrl = response.nextUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar garantías: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreWarranties() async {
    if (_isLoadingMore || _nextPageUrl == null) return;
    setState(() { _isLoadingMore = true; });

    try {
      final PaginatedResponse<Warranty> response =
          await _salesService.getMyWarranties(url: _nextPageUrl);
      if (mounted) {
        setState(() {
          _warranties.addAll(response.results);
          _nextPageUrl = response.nextUrl;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoadingMore = false; });
      }
    }
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('d \'de\' MMMM, y', 'es_ES').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoaded) {
      _hasLoaded = true;
      _fetchWarranties();
    }

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchWarranties,
            color: const Color(0xFF8B1E3F),
            child: _warranties.isEmpty
                ? Stack( // Usamos un Stack para que el RefreshIndicator funcione en una lista vacía
                    children: [
                      ListView(
                        physics: const AlwaysScrollableScrollPhysics(), // <- La clave
                      ),
                      const Center(
                        child: Text(
                          'No tienes garantías activas.',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    // --- ¡Y CAMBIO AQUÍ! ---
                    // Añadimos 'physics' para que siempre se pueda deslizar
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    itemCount: _warranties.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _warranties.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final warranty = _warranties[index];
                      return Card(
                        color: Colors.white,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          leading: Image.network(
                            warranty.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.image_not_supported),
                          ),
                          title: Text(
                            warranty.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Vence: ${_formatDate(warranty.expirationDate)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing: const Icon(Icons.shield, color: Colors.green),
                        ),
                      );
                    },
                  ),
          );
  }
}