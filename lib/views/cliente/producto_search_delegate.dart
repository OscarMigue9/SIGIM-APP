import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/producto.dart';
import '../../controllers/cliente_controller.dart';

class ProductoSearchDelegate extends SearchDelegate<Producto?> {
  final WidgetRef ref;

  ProductoSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Escribe para buscar productos...'),
      );
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Producto>>(
      future: ref.read(clienteServiceProvider).buscarProductos(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final productos = snapshot.data ?? [];

        if (productos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron productos',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getCategoriaColor(producto.categoria).withValues(alpha: 0.2),
                child: Icon(
                  _getCategoriaIcon(producto.categoria),
                  color: _getCategoriaColor(producto.categoria),
                ),
              ),
              title: Text(producto.nombre),
              subtitle: Text('${producto.categoria} • \$${producto.precio.toStringAsFixed(2)}'),
              trailing: producto.tieneStock 
                  ? IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        ref.read(carritoControllerProvider.notifier).agregarProducto(producto);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${producto.nombre} agregado al carrito')),
                        );
                      },
                    )
                  : Text(
                      'Sin stock',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
              onTap: () {
                close(context, producto);
                // Mostrar detalle del producto
                _mostrarDetalleProducto(context, producto);
              },
            );
          },
        );
      },
    );
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'muebles': return Colors.brown;
      case 'decoración': return Colors.purple;
      case 'cocina': return Colors.green;
      case 'dormitorio': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'muebles': return Icons.chair;
      case 'decoración': return Icons.brush;
      case 'cocina': return Icons.kitchen;
      case 'dormitorio': return Icons.bed;
      default: return Icons.category;
    }
  }

  void _mostrarDetalleProducto(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(producto.nombre),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SKU: ${producto.sku}'),
              Text('Categoría: ${producto.categoria}'),
              if (producto.dimensiones != null)
                Text('Dimensiones: ${producto.dimensiones}'),
              if (producto.material != null)
                Text('Material: ${producto.material}'),
              if (producto.color != null)
                Text('Color: ${producto.color}'),
              const SizedBox(height: 8),
              Text(
                'Precio: \$${producto.precio.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
              Text('Stock disponible: ${producto.stock}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (producto.tieneStock)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(carritoControllerProvider.notifier).agregarProducto(producto);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${producto.nombre} agregado al carrito')),
                );
              },
              child: const Text('Agregar al Carrito'),
            ),
        ],
      ),
    );
  }
}