import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proyect_movil/services/delivery_service.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final int deliveryId;

  const DeliveryDetailScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  bool _isLoading = true;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await _deliveryService.getDeliveryDetails(widget.deliveryId);
      setState(() {
        _order = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Lógica inteligente para avanzar el estado con un clic
  Future<void> _advanceState() async {
    if (_order == null) return;
    String currentStatus = _order!['status'] ?? 'ASSIGNED';
    
    String? nextStatus;
    String confirmMessage = "";

    if (currentStatus == 'ASSIGNED') {
      nextStatus = 'IN_TRANSIT';
      confirmMessage = "¿Iniciar ruta hacia el cliente?";
    } else if (currentStatus == 'IN_TRANSIT') {
      nextStatus = 'DELIVERED';
      confirmMessage = "¿Confirmar que el pedido fue entregado?";
    } else {
      return; // Ya está entregado, no hace nada
    }

    // Diálogo de confirmación
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Acción"),
        content: Text(confirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text("Confirmar")
          ),
        ],
      ),
    ) ?? false;

    if (confirm && nextStatus != null) {
      await _updateStatus(nextStatus);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    bool success = await _deliveryService.updateDeliveryStatus(widget.deliveryId, newStatus);
    if (success) {
      await _loadDetails();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado actualizado ✅'), backgroundColor: Colors.green));
    } else {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar'), backgroundColor: Colors.red));
    }
  }

  Future<void> _openMap() async {
    if (_order == null) return;
    final lat = _order!['latitude'];
    final lng = _order!['longitude'];
    
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sin coordenadas GPS")));
      return;
    }

    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      final Uri webUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${widget.deliveryId}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text("Error cargando datos"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 1. BOTÓN DE ESTADO (GIGANTE Y CLICKEABLE)
                      _buildStatusCard(),
                      
                      const SizedBox(height: 16),

                      // 2. DIRECCIÓN Y MAPA (OPTIMIZADO)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Dirección de Entrega", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Dirección principal
                              Text(
                                _order!['address'] ?? 'Sin dirección',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              // Referencia
                              const SizedBox(height: 4),
                              Text(
                                "Referencia: ${_order!['description'] ?? 'Sin referencia'}",
                                style: TextStyle(fontSize: 14, color: Colors.grey[700], fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              // Botón de Mapa
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openMap,
                                  icon: const Icon(Icons.map, color: Colors.white),
                                  label: const Text("INICIAR VIAJE"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. DATOS DE FACTURACIÓN (Cliente y Total)
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Datos de Facturación", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              const Divider(),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.person_outline, color: Colors.black),
                                title: Text(_order!['customer_name'] ?? 'Cliente Anónimo'),
                                subtitle: const Text("Cliente"),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.monetization_on_outlined, color: Colors.green),
                                title: Text("Bs. ${_order!['sale_total'] ?? '0.00'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                subtitle: const Text("Total Pagado"),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. LISTA DE PRODUCTOS (Corregido para leer "products")
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("📦 Productos a Entregar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      if (_order!['products'] != null && (_order!['products'] as List).isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (_order!['products'] as List).length,
                          itemBuilder: (context, index) {
                            final product = _order!['products'][index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade50,
                                  child: Text("${product['quantity'] ?? 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                title: Text(product['product_name'] ?? 'Producto'),
                                // Si tu JSON tuviera precio por producto, iría aquí
                              ),
                            );
                          },
                        )
                      else
                        const Center(child: Text("No hay productos listados")),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  // Widget para el Botón de Estado Dinámico
  Widget _buildStatusCard() {
    String status = _order!['status'] ?? 'ASSIGNED';
    Color color;
    String text;
    String subtext;
    IconData icon;

    if (status == 'ASSIGNED') {
      color = Colors.orange;
      text = "ASIGNADO";
      subtext = "Toca para indicar 'EN CAMINO' 🚚";
      icon = Icons.assignment_ind;
    } else if (status == 'IN_TRANSIT') {
      color = Colors.blue;
      text = "EN CAMINO";
      subtext = "Toca para finalizar 'ENTREGADO' ✅";
      icon = Icons.local_shipping;
    } else {
      color = Colors.green;
      text = "ENTREGADO";
      subtext = "Pedido finalizado";
      icon = Icons.check_circle;
    }

    return InkWell(
      onTap: status == 'DELIVERED' ? null : _advanceState,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            if (status != 'DELIVERED') ...[
              const SizedBox(height: 4),
              Text(subtext, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }
}