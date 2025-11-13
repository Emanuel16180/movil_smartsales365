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
      return DateFormat('d \'de\' MMMM, y', 'es_ES').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8E8), // Fondo claro
      appBar: AppBar(
        title: Text('Recibo #${widget.purchaseId}'),
        backgroundColor: const Color(0xFF8B1E3F),
        foregroundColor: Colors.white,
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
                // Resumen
                Card(
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen de Compra',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B1E3F),
                          ),
                        ),
                        const Divider(height: 20),
                        _buildInfoRow('Cliente:', data['user']?['full_name'] ?? 'N/A'),
                        _buildInfoRow('Email:', data['user']?['email'] ?? 'N/A'),
                        _buildInfoRow('Fecha:', _formatDate(data['created_at'])),
                        _buildInfoRow('Estado:', data['status']),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          'Total Pagado:',
                          'Bs. ${data['total_amount']}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Productos
                Text(
                  'Productos Comprados (${details.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...details.map((item) => Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Image.network(
                          item['product']?['image_url'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (c,e,s) => Icon(Icons.image_not_supported),
                        ),
                        title: Text(item['product']?['name'] ?? 'Producto'),
                        subtitle: Text('Cantidad: ${item['quantity']}'),
                        trailing: Text('Bs. ${item['price_at_purchase']} c/u'),
                      ),
                    )),
                
                const SizedBox(height: 20),

                // Garantías
                Text(
                  'Garantías Activadas (${warranties.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...warranties.map((w) => Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.shield, color: Colors.green),
                        title: Text(w['product']?['name'] ?? 'Producto'),
                        subtitle: Text(
                          'Válida hasta: ${_formatDate(w['expiration_date'])}',
                        ),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Color(0xFF8B1E3F) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}