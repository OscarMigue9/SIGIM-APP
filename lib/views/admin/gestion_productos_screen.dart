import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/producto_controller.dart';
import '../../models/producto.dart';

class GestionProductosScreen extends ConsumerStatefulWidget {
  final bool autoOpenCreate;
  const GestionProductosScreen({super.key, this.autoOpenCreate = false});

  @override
  ConsumerState<GestionProductosScreen> createState() =>
      _GestionProductosScreenState();
}

class _GestionProductosScreenState
    extends ConsumerState<GestionProductosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productoControllerProvider.notifier).cargarProductos();
      if (widget.autoOpenCreate) {
        _mostrarDialogoProducto(context);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productoState = ref.watch(productoControllerProvider);
    final categoriasAsyncValue = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(productoControllerProvider.notifier).cargarProductos();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'stock_bajo') {
                ref
                    .read(productoControllerProvider.notifier)
                    .cargarProductosStockBajo();
              } else if (value == 'todos') {
                ref.read(productoControllerProvider.notifier).cargarProductos();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Row(
                  children: [
                    Icon(Icons.inventory),
                    SizedBox(width: 8),
                    Text('Todos los productos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stock_bajo',
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Stock bajo'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de b├║squeda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // B├║squeda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Buscar productos por nombre, SKU o categoría...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(productoControllerProvider.notifier)
                                  .buscarProductos('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    ref
                        .read(productoControllerProvider.notifier)
                        .buscarProductos(value);
                  },
                ),

                const SizedBox(height: 12),

                // Filtro por categor├¡a
                categoriasAsyncValue.when(
                  data: (categorias) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String?>(
                      value: _categoriaSeleccionada,
                      hint: const Text('Filtrar por categoría'),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        ...categorias.map(
                          (categoria) => DropdownMenuItem<String>(
                            value: categoria,
                            child: Text(categoria),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _categoriaSeleccionada = value;
                        });
                        ref
                            .read(productoControllerProvider.notifier)
                            .filtrarPorCategoria(value);
                      },
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => const SizedBox(),
                ),
              ],
            ),
          ),

          // Estad├¡sticas r├ípidas
          _buildEstadisticas(productoState),

          // Lista de productos
          Expanded(child: _buildProductosList(productoState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoProducto(context),
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEstadisticas(ProductoState state) {
    final productos = state.productos;
    final totalProductos = productos.length;
    final productosConStock = productos.where((p) => p.tieneStock).length;
    final productosStockBajo = productos.where((p) => p.stockBajo).length;
    final valorInventario = productos.fold<double>(
      0,
      (sum, p) => sum + (p.precio * p.stock),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEstadisticaItem(
                'Total',
                totalProductos.toString(),
                Icons.inventory_2,
                Colors.blue,
              ),
              _buildEstadisticaItem(
                'Con Stock',
                productosConStock.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildEstadisticaItem(
                'Stock Bajo',
                productosStockBajo.toString(),
                Icons.warning,
                Colors.orange,
              ),
              _buildEstadisticaItem(
                'Valor',
                '\$${valorInventario.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadisticaItem(
    String titulo,
    String valor,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(titulo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProductosList(ProductoState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(productoControllerProvider.notifier)
                  .cargarProductos(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.productos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay productos registrados'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.productos.length,
      itemBuilder: (context, index) {
        final producto = state.productos[index];
        return _buildProductoCard(producto);
      },
    );
  }

  Widget _buildProductoCard(Producto producto) {
    final stockColor = producto.stockBajo
        ? Colors.red
        : producto.tieneStock
        ? Colors.green
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getCategoriaColor(producto.categoria).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoriaIcon(producto.categoria),
            color: _getCategoriaColor(producto.categoria),
            size: 24,
          ),
        ),
        title: Text(
          producto.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${producto.sku}'),
            Text('Categoría: ${producto.categoria}'),
            Row(
              children: [
                Icon(Icons.inventory, size: 16, color: stockColor),
                const SizedBox(width: 4),
                Text(
                  'Stock: ${producto.stock}',
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: producto.stockBajo
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '\$${producto.precio}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, producto),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'ver',
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Ver detalles'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'stock',
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.purple),
                  SizedBox(width: 8),
                  Text('Ajustar Stock'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'muebles':
        return Colors.brown;
      case 'decoración':
        return Colors.pink;
      case 'cocina':
        return Colors.orange;
      case 'dormitorio':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'muebles':
        return Icons.chair;
      case 'decoración':
        return Icons.palette;
      case 'cocina':
        return Icons.kitchen;
      case 'dormitorio':
        return Icons.bed;
      default:
        return Icons.category;
    }
  }

  void _handleMenuAction(String action, Producto producto) {
    switch (action) {
      case 'ver':
        _mostrarDetallesProducto(context, producto);
        break;
      case 'editar':
        _mostrarDialogoProducto(context, producto: producto);
        break;
      case 'stock':
        _mostrarDialogoAjustarStock(context, producto);
        break;
      case 'eliminar':
        _mostrarDialogoEliminar(context, producto);
        break;
    }
  }

  void _mostrarDialogoProducto(BuildContext context, {Producto? producto}) {
    showDialog(
      context: context,
      builder: (context) => _ProductoDialog(producto: producto),
    );
  }

  void _mostrarDetallesProducto(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (context) => _DetallesProductoDialog(producto: producto),
    );
  }

  void _mostrarDialogoAjustarStock(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (context) => _AjustarStockDialog(producto: producto),
    );
  }

  void _mostrarDialogoEliminar(BuildContext context, Producto producto) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro que quieres eliminar "${producto.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              navigator.pop();
              final success = await ref
                  .read(productoControllerProvider.notifier)
                  .eliminarProducto(producto.idProducto!);

              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Producto eliminado exitosamente'
                        : 'Error al eliminar producto',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Di├ílogos auxiliares
class _ProductoDialog extends ConsumerStatefulWidget {
  final Producto? producto;

  const _ProductoDialog({this.producto});

  @override
  ConsumerState<_ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends ConsumerState<_ProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nombreController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _dimensionesController = TextEditingController();
  final _materialController = TextEditingController();
  final _colorController = TextEditingController();
  final _precioController = TextEditingController();
  final _costoController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.producto != null) {
      final p = widget.producto!;
      _skuController.text = p.sku;
      _nombreController.text = p.nombre;
      _categoriaController.text = p.categoria;
      _dimensionesController.text = p.dimensiones ?? '';
      _materialController.text = p.material ?? '';
      _colorController.text = p.color ?? '';
      _precioController.text = p.precio.toString();
      _costoController.text = p.costo.toString();
      _stockController.text = p.stock.toString();
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nombreController.dispose();
    _categoriaController.dispose();
    _dimensionesController.dispose();
    _materialController.dispose();
    _colorController.dispose();
    _precioController.dispose();
    _costoController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.producto != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Producto' : 'Crear Producto'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El SKU es requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoriaController,
                        decoration: const InputDecoration(
                          labelText: 'Categoría *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La categoría es requerida';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dimensionesController,
                        decoration: const InputDecoration(
                          labelText: 'Dimensiones',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _materialController,
                        decoration: const InputDecoration(
                          labelText: 'Material',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(
                          labelText: 'Color',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioController,
                        decoration: const InputDecoration(
                          labelText: 'Precio *',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El precio es requerido';
                          }
                          final precio = double.tryParse(value);
                          if (precio == null || precio <= 0) {
                            return 'Precio inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _costoController,
                        decoration: const InputDecoration(
                          labelText: 'Costo *',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El costo es requerido';
                          }
                          final costo = double.tryParse(value);
                          if (costo == null || costo < 0) {
                            return 'Costo inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El stock es requerido';
                          }
                          final stock = int.tryParse(value);
                          if (stock == null || stock < 0) {
                            return 'Stock inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardarProducto,
          child: Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final producto = Producto(
      idProducto: widget.producto?.idProducto,
      sku: _skuController.text.trim(),
      nombre: _nombreController.text.trim(),
      categoria: _categoriaController.text.trim(),
      dimensiones: _dimensionesController.text.trim().isNotEmpty
          ? _dimensionesController.text.trim()
          : null,
      material: _materialController.text.trim().isNotEmpty
          ? _materialController.text.trim()
          : null,
      color: _colorController.text.trim().isNotEmpty
          ? _colorController.text.trim()
          : null,
      precio: double.parse(_precioController.text),
      costo: double.parse(_costoController.text),
      stock: int.parse(_stockController.text),
    );

    final success = widget.producto != null
        ? await ref
              .read(productoControllerProvider.notifier)
              .actualizarProducto(producto)
        : await ref
              .read(productoControllerProvider.notifier)
              .crearProducto(producto);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.producto != null
                  ? 'Producto actualizado exitosamente'
                  : 'Producto creado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(productoControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Error al guardar producto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _DetallesProductoDialog extends StatelessWidget {
  final Producto producto;

  const _DetallesProductoDialog({required this.producto});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(producto.nombre),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('SKU:', producto.sku),
            _buildDetailRow('Categoría:', producto.categoria),
            if (producto.dimensiones != null)
              _buildDetailRow('Dimensiones:', producto.dimensiones!),
            if (producto.material != null)
              _buildDetailRow('Material:', producto.material!),
            if (producto.color != null)
              _buildDetailRow('Color:', producto.color!),
            _buildDetailRow('Precio:', '\$${producto.precio}'),
            _buildDetailRow('Costo:', '\$${producto.costo}'),
            _buildDetailRow(
              'Margen:',
              '${(producto.costo != null && producto.costo! > 0) ? (((producto.precio - producto.costo!) / producto.costo!) * 100).toStringAsFixed(1) : '0.0'}%',
            ),
            _buildDetailRow('Stock:', '${producto.stock}'),
            _buildDetailRow(
              'Estado:',
              producto.tieneStock ? 'Disponible' : 'Sin Stock',
            ),
            if (producto.stockBajo)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Stock Bajo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AjustarStockDialog extends ConsumerStatefulWidget {
  final Producto producto;

  const _AjustarStockDialog({required this.producto});

  @override
  ConsumerState<_AjustarStockDialog> createState() =>
      _AjustarStockDialogState();
}

class _AjustarStockDialogState extends ConsumerState<_AjustarStockDialog> {
  final _stockController = TextEditingController();
  final _motivoController = TextEditingController(text: 'Ajuste manual');

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
      title: const Text('Ajustar Stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Producto: ${widget.producto.nombre}'),
          const SizedBox(height: 8),
          Text('Stock actual: ${widget.producto.stock}'),
          const SizedBox(height: 16),
          TextField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Nuevo Stock',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motivoController,
            decoration: const InputDecoration(
              labelText: 'Motivo del ajuste',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _ajustarStock,
          child: const Text('Actualizar'),
        ),
      ],
    );
  }

  Future<void> _ajustarStock() async {
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

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Ajuste aplicado exitosamente'
                : (ref.read(productoControllerProvider).error ??
                      'Error al aplicar ajuste'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
