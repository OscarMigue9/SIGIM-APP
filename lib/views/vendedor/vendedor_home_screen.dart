import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../config/config_screen.dart';
import '../../services/metrics_service.dart';
import 'inventario_vendedor_screen.dart';
import 'pedidos_vendedor_screen.dart';
import 'nuevo_pedido_screen.dart';
import 'ventas_vendedor_screen.dart';
import '../../controllers/alertas_controller.dart';

class VendedorHomeScreen extends ConsumerStatefulWidget {
  const VendedorHomeScreen({super.key});

  @override
  ConsumerState<VendedorHomeScreen> createState() => _VendedorHomeScreenState();
}

class _VendedorHomeScreenState extends ConsumerState<VendedorHomeScreen> {
  final _metricsService = MetricsService();
  Map<String, dynamic>? _metrics;
  List<Map<String, dynamic>> _ventasRecientes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = ref.read(authControllerProvider).usuario;
      if (auth != null && auth.idUsuario != null) {
        try {
          final vendedorId = auth.idUsuario!;
          final m = await _metricsService.getVendedorMetrics(vendedorId);
          final ventas = await _metricsService.getRecentSalesVendedor(vendedorId, limit: 5);
          if (!mounted) return;
          setState(() {
            _metrics = m;
            _ventasRecientes = ventas;
            _loading = false;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() { _loading = false; });
        }
      } else {
        setState(() { _loading = false; });
      }
    });
  }
  Future<void> _logout() async {
    final confirmed = await _showLogoutDialog();
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      // El AuthWrapper se encargará automáticamente de navegar al login
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Vendedor'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConfigScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildVendedorContent(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Consumer(builder: (context, ref, _) {
            final user = ref.watch(currentUserProvider);
            return UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade700,
              ),
              accountName: Text(user?.nombreCompleto ?? 'Vendedor'),
              accountEmail: Text(user?.email ?? '-'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.storefront,
                  color: Colors.green,
                  size: 40,
                ),
              ),
            );
          }),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                Consumer(builder: (context, ref, _) {
                  final alertas = ref.watch(alertasControllerProvider);
                  return _buildDrawerItem(
                    icon: Icons.warehouse,
                    title: 'Inventario',
                    badge: alertas.stockBajo,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const InventarioVendedorScreen()));
                    },
                  );
                }),
                _buildDrawerItem(
                  icon: Icons.receipt_long,
                  title: 'Pedidos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PedidosVendedorScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.point_of_sale,
                  title: 'Ventas',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VentasVendedorScreen()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(icon, color: Colors.green.shade700),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      title: Text(title),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildVendedorContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Ventas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSalesMetrics(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentSales(),
        ],
      ),
    );
  }

  Widget _buildSalesMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Ventas Hoy',
            value: _metrics != null ? '\$${((_metrics!['ventasHoy'] ?? 0) as num).toStringAsFixed(2)}' : '---',
            icon: Icons.today,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Pedidos',
            value: _metrics != null ? ((_metrics!['pedidosHoy'] ?? 0) as num).toString() : '---',
            icon: Icons.receipt_long,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                title: 'Ver Inventario',
                icon: Icons.inventory_2,
                color: Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventarioVendedorScreen())),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                title: 'Mis Ventas',
                icon: Icons.bar_chart,
                color: Colors.purple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VentasVendedorScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Botón reutilizable para acciones rápidas
  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ventas Recientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _ventasRecientes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Sin ventas recientes', style: TextStyle(color: Colors.grey.shade600)),
                )
              : Column(
                  children: _ventasRecientes.map((v) {
                    return _buildSaleItem(
                      customerName: v['nombreCliente'] as String,
                      amount: '\$${(v['total'] as num).toStringAsFixed(2)}',
                      products: v['productos'] as String,
                      time: _formatearTiempo(v['fecha']),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoPedidoScreen())),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Pedido'),
          ),
        ),
      ],
    );
  }

  String _formatearTiempo(dynamic iso) {
    try {
      final fecha = DateTime.parse(iso as String);
      final diff = DateTime.now().difference(fecha);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildSaleItem({
    required String customerName,
    required String amount,
    required String products,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  products,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // (intencionalmente sin snackbar por ahora; se añadirá si se requiere)
}
