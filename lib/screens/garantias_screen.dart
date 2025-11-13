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
    if(mounted) setState(() => _isLoading = true);
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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar garantías: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreWarranties() async {
    if (_isLoadingMore || _nextPageUrl == null) return;
    if(mounted) setState(() => _isLoadingMore = true);

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
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      // Usamos un formato más limpio para la fecha de vencimiento
      return DateFormat('dd/MM/yyyy', 'es_ES').format(parsedDate);
    } catch (e) {
      return date; // Devuelve la fecha original si no se puede parsear
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoaded) {
      _hasLoaded = true;
      _fetchWarranties();
    }
    final theme = Theme.of(context);

    // No usamos Scaffold
    return RefreshIndicator(
      onRefresh: _fetchWarranties,
      color: theme.colorScheme.primary, // Color azul
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _warranties.isEmpty
              ? Stack( 
                  children: [
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12), // Padding general
                  itemCount: _warranties.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _warranties.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final warranty = _warranties[index];

                    // --- ¡AQUÍ ESTÁ LA LÓGICA DE FECHA CORRECTA! ---
                    final DateTime now = DateTime.now();
                    // Obtenemos 'hoy' a las 00:00:00
                    final DateTime today = DateTime(now.year, now.month, now.day); 
                    final DateTime? expirationDate = DateTime.tryParse(warranty.expirationDate);
                    
                    bool isExpired = true; // Por defecto, vencida si hay error
                    
                    if (expirationDate != null) {
                      // Obtenemos la fecha de expiración a las 00:00:00
                      final DateTime expiryDay = DateTime(expirationDate.year, expirationDate.month, expirationDate.day);
                      
                      // La garantía está vencida si la fecha de expiración es ANTERIOR a hoy.
                      // Si vence "hoy", todavía está activa.
                      isExpired = expiryDay.isBefore(today);
                    }
                    
                    final String statusText = isExpired ? 'Garantía Vencida' : 'Garantía Activa';
                    final Color statusColor = isExpired ? Colors.red : Colors.green;
                    final Color statusBgColor = isExpired ? Colors.red.withAlpha(50) : Colors.green.withAlpha(50);
                    final IconData statusIcon = isExpired ? Icons.cancel_outlined : Icons.verified_outlined;
                    // ------------------------------------------------

                    return Card(
                      elevation: 2,
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                warranty.imageUrl,
                                width: 70, 
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    warranty.productName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    // Usamos el formato dd/MM/yyyy
                                    'Vence: ${_formatDate(warranty.expirationDate)}',
                                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  // --- CHIP DE ESTADO DINÁMICO ---
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBgColor, // Color dinámico
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusText, // Texto dinámico
                                      style: TextStyle(
                                        color: statusColor, // Color dinámico
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // --- ¡ÍCONO DINÁMICO Y CORREGIDO! ---
                            Icon(statusIcon, color: statusColor, size: 28),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
  }
}