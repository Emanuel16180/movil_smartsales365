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
    if(mounted) setState(() => _isLoading = true);
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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar compras: $e')),
        );
      }
    }
  }

  Future<void> _loadMorePurchases() async {
    if (_isLoadingMore || _nextPageUrl == null) return;
    if(mounted) setState(() => _isLoadingMore = true);

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
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      // Formato más corto y limpio
      return DateFormat('dd/MM/yyyy', 'es_ES').format(parsedDate);
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
    final theme = Theme.of(context);

    // No usamos Scaffold, la pantalla de Perfil ya tiene uno.
    return RefreshIndicator(
      onRefresh: _fetchPurchases,
      color: theme.colorScheme.primary, // Color azul
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchases.isEmpty
              ? Stack( 
                  children: [
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(), 
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
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12), // Padding general
                  itemCount: _purchases.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _purchases.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final purchase = _purchases[index];
                    return Card(
                      elevation: 2,
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Compra #${purchase.id}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                Text(
                                  'Bs. ${purchase.totalAmount}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            
                            // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
                            // Cambiamos Row por Wrap para evitar el overflow
                            Wrap(
                              spacing: 8.0, // Espacio horizontal entre chips
                              runSpacing: 4.0, // Espacio vertical si bajan de línea
                              children: [
                                _buildInfoChip(Icons.calendar_today_outlined, _formatDate(purchase.createdAt)),
                                _buildInfoChip(Icons.shopping_bag_outlined, '${purchase.itemCount} items'),
                              ],
                            ),
                            // --- FIN DE LA CORRECCIÓN ---

                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                                label: const Text('Ver Recibo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary.withAlpha(40),
                                  foregroundColor: theme.colorScheme.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)
                                  ),
                                ),
                                onPressed: () {
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
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
  }

  // Widget de apoyo para los chips de info
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Importante para que el chip no se expanda
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}