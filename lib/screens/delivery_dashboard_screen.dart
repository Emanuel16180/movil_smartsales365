// lib/screens/delivery_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:proyect_movil/services/auth_service.dart';
import 'package:proyect_movil/services/delivery_service.dart';
import 'package:proyect_movil/screens/login_screen.dart';
import 'package:proyect_movil/screens/delivery_detail_screen.dart'; // <--- Importar detalle

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  final AuthService _authService = AuthService();
  List<dynamic> _deliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() => _isLoading = true);
    try {
      final data = await _deliveryService.getMyDeliveries();
      setState(() {
        _deliveries = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Navegar al detalle
  void _goToDetail(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeliveryDetailScreen(deliveryId: id)),
    );
    // Al volver, recargamos la lista por si cambió el estado
    _loadDeliveries();
  }

  Color _getStatusColor(String? status) {
    if (status == 'IN_TRANSIT') return Colors.blue.shade100;
    if (status == 'DELIVERED') return Colors.green.shade100;
    return Colors.orange.shade100; // Pending
  }

  String _getStatusText(String? status) {
    if (status == 'IN_TRANSIT') return 'EN CAMINO';
    if (status == 'DELIVERED') return 'ENTREGADO';
    return 'PENDIENTE';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Entregas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authService.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveries.isEmpty
              ? const Center(child: Text("No tienes entregas asignadas"))
              : RefreshIndicator(
                  onRefresh: _loadDeliveries,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _deliveries.length,
                    itemBuilder: (context, index) {
                      final item = _deliveries[index];
                      final status = item['status'] ?? 'PENDING';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell( // <--- Hacemos clickeable toda la tarjeta
                          onTap: () => _goToDetail(item['id']),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getStatusText(status),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    Text("#${item['id']}", style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: Colors.black87),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['address'] ?? 'Sin dirección',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 32.0),
                                  child: Text(
                                    item['description'] ?? 'Sin referencia',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "Ver detalles >",
                                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}