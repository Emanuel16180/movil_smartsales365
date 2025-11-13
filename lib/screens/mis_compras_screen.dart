// lib/screens/mis_compras_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyect_movil/models/paginated_response.dart';
import 'package:proyect_movil/models/purchase_model.dart';
import 'package:proyect_movil/services/sales_service.dart';
import 'package:proyect_movil/screens/purchase_detail_screen.dart';

class MisComprasScreen extends StatefulWidget {
  const MisComprasScreen({super.key});

  @override
  State<MisComprasScreen> createState() => _MisComprasScreenState();
}

class _MisComprasScreenState extends State<MisComprasScreen> {
  final SalesService _salesService = SalesService();
  final ScrollController _scrollController = ScrollController();
  List<Purchase> _purchases = [];
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
        _loadMorePurchases();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPurchases() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final PaginatedResponse<Purchase> response =
          await _salesService.getMyPurchases();
      if (mounted) {
        setState(() {
          _purchases = response.results;
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
          SnackBar(content: Text('Error al cargar compras: $e')),
        );
      }
    }
  }

  Future<void> _loadMorePurchases() async {
    if (_isLoadingMore || _nextPageUrl == null) return;
    setState(() { _isLoadingMore = true; });

    try {
      final PaginatedResponse<Purchase> response =
          await _salesService.getMyPurchases(url: _nextPageUrl);
      if (mounted) {
        setState(() {
          _purchases.addAll(response.results);
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
      _fetchPurchases();
    }

    // --- ¡CAMBIO AQUÍ! ---
    // Si la lista está vacía, mostramos un RefreshIndicator simple.
    // Si la lista tiene contenido, el RefreshIndicator envuelve al ListView.
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchPurchases,
            color: const Color(0xFF8B1E3F),
            child: _purchases.isEmpty
                ? Stack( // Usamos un Stack para que el RefreshIndicator funcione en una lista vacía
                    children: [
                      ListView(
                        physics: const AlwaysScrollableScrollPhysics(), // <- La clave
                      ),
                      const Center(
                        child: Text(
                          'No has realizado ninguna compra.',
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
                    itemCount: _purchases.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _purchases.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final purchase = _purchases[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            'Compra #${purchase.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Fecha: ${_formatDate(purchase.createdAt)}\nTotal: Bs. ${purchase.totalAmount}',
                          ),
                          trailing: Text(
                            '${purchase.itemCount} items',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PurchaseDetailScreen(
                                  purchaseId: purchase.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          );
  }
}