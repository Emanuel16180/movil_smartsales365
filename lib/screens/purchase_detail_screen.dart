// lib/screens/purchase_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyect_movil/services/sales_service.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final int purchaseId;
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  final SalesService _salesService = SalesService();
  late Future<Map<String, dynamic>> _receiptFuture;

  @override
  void initState() {
    super.initState();
    _receiptFuture = _salesService.getPurchaseReceipt(widget.purchaseId);
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('d \'de\' MMMM, y \'a las\' HH:mm', 'es_ES').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Fondo gris claro
      appBar: AppBar(
        title: Text('Recibo #${widget.purchaseId}'),
        backgroundColor: Colors.white, // Fondo blanco
        foregroundColor: Colors.black, // Texto e íconos negros
        elevation: 1, // Sombra ligera
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _receiptFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontró el recibo.'));
          }

          final data = snapshot.data!;
          final List<dynamic> details = data['details'] ?? [];
          final List<dynamic> warranties = data['activated_warranties'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Resumen (Sin cambios) ---
                Card(
                  elevation: 2,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Resumen de Compra',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary, // Azul
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoTile(Icons.person_outline, 'Cliente', data['user']?['full_name'] ?? 'N/A'),
                        _buildInfoTile(Icons.mail_outline, 'Email', data['user']?['email'] ?? 'N/A'),
                        _buildInfoTile(Icons.calendar_today_outlined, 'Fecha', _formatDate(data['created_at'])),
                        _buildInfoTile(Icons.info_outline, 'Estado', data['status']),
                        const Divider(height: 20, indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Pagado:', style: theme.textTheme.titleLarge),
                              Text(
                                'Bs. ${data['total_amount']}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Productos (Sin cambios) ---
                Text(
                  'Productos Comprados (${details.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: details.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final item = details[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['product']?['image_url'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported),
                          ),
                        ),
                        title: Text(item['product']?['name'] ?? 'Producto'),
                        subtitle: Text('Cantidad: ${item['quantity']}'),
                        trailing: Text('Bs. ${item['price_at_purchase']} c/u', style: const TextStyle(fontWeight: FontWeight.w500)),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),

                // --- Garantías ---
                Text(
                  'Garantías Activadas (${warranties.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 10),
                warranties.isEmpty
                ? const Text('Esta compra no activó garantías.', style: TextStyle(color: Colors.black54))
                : Card(
                  elevation: 2,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: warranties.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final w = warranties[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        // --- ¡AQUÍ ESTÁ EL ÍCONO CAMBIADO! ---
                        leading: const Icon(Icons.verified_outlined, color: Colors.green),
                        title: Text(w['product']?['name'] ?? 'Producto'),
                        subtitle: Text(
                          'Válida hasta: ${_formatDate(w['expiration_date'])}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget de apoyo para el resumen
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(label, style: const TextStyle(color: Colors.black54)),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 16
        ),
      ),
    );
  }
}