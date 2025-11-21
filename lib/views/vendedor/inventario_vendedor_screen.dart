import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/producto_controller.dart';
import '../../models/producto.dart';

class InventarioVendedorScreen extends ConsumerStatefulWidget {
  const InventarioVendedorScreen({super.key});

  @override
  ConsumerState<InventarioVendedorScreen> createState() =>
      _InventarioVendedorScreenState();
}

class _InventarioVendedorScreenState
    extends ConsumerState<InventarioVendedorScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(productoControllerProvider.notifier).cargarProductos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productoControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => ref
                  .read(productoControllerProvider.notifier)
                  .buscarProductos(v),
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: state.productos.isEmpty
                ? Center(child: Text(state.error ?? 'Sin productos'))
                : ListView.separated(
                    itemCount: state.productos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = state.productos[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            p.nombre.isNotEmpty
                                ? p.nombre[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(p.nombre),
                        subtitle: Text(
                          'SKU: ${p.sku} • ${p.categoria}\nStock: ${p.stock}',
                        ),
                        isThreeLine: true,
                        onTap: () => _mostrarDialogoAjuste(context, p),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '\$${p.precio.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (p.stock <= 5)
                              const Text(
                                'Stock bajo',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAjuste(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (_) => _AjusteStockVendedorDialog(producto: producto),
    );
  }
}

class _AjusteStockVendedorDialog extends ConsumerStatefulWidget {
  final Producto producto;

  const _AjusteStockVendedorDialog({required this.producto});

  @override
  ConsumerState<_AjusteStockVendedorDialog> createState() =>
      _AjusteStockVendedorDialogState();
}

class _AjusteStockVendedorDialogState
    extends ConsumerState<_AjusteStockVendedorDialog> {
  final _stockController = TextEditingController();
  final _motivoController = TextEditingController(text: 'Ajuste de vendedor');

  @override
  void initState() {
    super.initState();
    _stockController.text = widget.producto.stock.toString();
  }

  @override
  void dispose() {
    _stockController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajustar stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.producto.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Stock actual: ${widget.producto.stock}'),
          const SizedBox(height: 16),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nuevo stock',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motivoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Motivo del ajuste',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _aplicarAjuste, child: const Text('Guardar')),
      ],
    );
  }

  Future<void> _aplicarAjuste() async {
    final nuevoStock = int.tryParse(_stockController.text);
    if (nuevoStock == null || nuevoStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock inválido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final motivo = _motivoController.text.trim();
    if (motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El motivo es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref
        .read(productoControllerProvider.notifier)
        .aplicarAjusteInventario(
          idProducto: widget.producto.idProducto!,
          nuevoStock: nuevoStock,
          motivo: motivo,
        );

    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Ajuste aplicado'
              : (ref.read(productoControllerProvider).error ??
                    'Error al aplicar ajuste'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
