import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/producto_controller.dart';
import '../../models/producto.dart';

class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  bool _soloStockBajo = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(productoControllerProvider.notifier).cargarProductos(),
            tooltip: 'Recargar',
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => setState(() => _soloStockBajo = !_soloStockBajo),
            icon: Icon(_soloStockBajo ? Icons.list : Icons.warning_amber_outlined, color: Colors.white),
            label: Text(_soloStockBajo ? 'Ver Todos' : 'Stock Bajo', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productoControllerProvider.notifier).cargarProductos(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductoState state) {
    final lista = _soloStockBajo ? state.productosStockBajo : state.productos;

    if (state.productos.isEmpty) {
      return const Center(child: Text('No hay productos en inventario'));
    }

    final totalProductos = state.productos.length;
    final totalUnidades = state.productos.fold<int>(0, (sum, p) => sum + p.stock);
    final valorInventario = state.productos.fold<double>(0, (sum, p) => sum + (p.precio * p.stock));
    final lowStock = state.productosStockBajo.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildKpis(totalProductos, totalUnidades, valorInventario, lowStock),
        const SizedBox(height: 16),
        Row(
          children: [
            Chip(
              label: Text(_soloStockBajo ? 'Mostrando stock bajo ($lowStock)' : 'Todos los productos ($totalProductos)'),
              avatar: Icon(_soloStockBajo ? Icons.warning : Icons.inventory_2, color: _soloStockBajo ? Colors.orange : Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Listado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...lista.map(_buildItem),
        if (_soloStockBajo && lista.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(child: Text('No hay productos con stock bajo')),
          ),
      ],
    );
  }

  Widget _buildKpis(int totalProductos, int totalUnidades, double valorInventario, int lowStock) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 2 columnas en pantallas angostas, 4 en anchas
        final isNarrow = constraints.maxWidth < 600;
        final crossAxisCount = isNarrow ? 2 : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: isNarrow ? 2.2 : 2.8,
          children: [
            _kpi('Productos', '$totalProductos', Icons.inventory_2, Colors.blue),
            _kpi('Unidades', '$totalUnidades', Icons.format_list_numbered, Colors.purple),
            _kpi('Valor', '\$${valorInventario.toStringAsFixed(0)}', Icons.attach_money, Colors.green),
            _kpi('Stock bajo', '$lowStock', Icons.warning, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _kpi(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Producto p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(p.nombre),
        subtitle: Text('SKU: ${p.sku} • Cat: ${p.categoria}'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Stock: ${p.stock}', style: TextStyle(color: p.stockBajo ? Colors.red : Colors.green)),
            Text('\$${p.precio}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}

// Barra de filtros avanzada removida; se dejó solo el botón de stock bajo

// Pantalla de Stock Bajo eliminada; se integrará como filtro en el inventario
