import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/producto.dart';
import '../../models/pedido.dart';
import 'producto_search_delegate.dart';
import 'checkout_screen.dart';
import 'direcciones_screen.dart';
import 'metodos_pago_screen.dart';
import '../perfil/perfil_screen.dart';
import '../info/ayuda_screen.dart';
import '../info/acerca_screen.dart';

class ClienteHomeScreen extends ConsumerStatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  ConsumerState<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends ConsumerState<ClienteHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  void _cargarDatosIniciales() {
    // Cargar productos destacados y categorías
    ref.read(tiendaControllerProvider.notifier).cargarDatosIniciales();

    // Cargar pedidos del usuario actual si está autenticado
    final usuario = ref.read(authControllerProvider).usuario;
    if (usuario != null) {
      ref
          .read(pedidosClienteControllerProvider.notifier)
          .cargarPedidos(usuario.idUsuario!);
    }
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
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedIndex == 0) // Solo en la tienda
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _mostrarBusqueda,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildTiendaTab(),
          _buildCarritoTab(),
          _buildPedidosTab(),
          _buildPerfilTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Tienda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tienda';
      case 1:
        return 'Mi Carrito';
      case 2:
        return 'Mis Pedidos';
      case 3:
        return 'Mi Perfil';
      default:
        return 'Tienda';
    }
  }

  Widget _buildTiendaTab() {
    final tiendaState = ref.watch(tiendaControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!tiendaState.mostrarTodosLosProductos) ...[
            _buildWelcomeSection(),
            const SizedBox(height: 20),
          ],
          _buildCategoriesSection(),
          const SizedBox(height: 20),
          if (tiendaState.mostrarTodosLosProductos)
            _buildTodosLosProductos()
          else
            _buildProductsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Bienvenido a SIGIM!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Encuentra los mejores productos para tu hogar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final tiendaState = ref.watch(tiendaControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorías',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: tiendaState.categorias.isEmpty
              ? const Center(child: Text('Cargando categorías...'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tiendaState.categorias.length,
                  itemBuilder: (context, index) {
                    final categoria = tiendaState.categorias[index];
                    return _buildCategoryCard(
                      categoria,
                      _getCategoriaIcon(categoria),
                      _getCategoriaColor(categoria),
                      onTap: () {
                        ref
                            .read(tiendaControllerProvider.notifier)
                            .filtrarPorCategoria(categoria);
                        setState(() => _selectedIndex = 0);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String name,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    final tiendaState = ref.watch(tiendaControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Productos Destacados',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(tiendaControllerProvider.notifier)
                    .mostrarTodosLosProductos();
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (tiendaState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (tiendaState.error != null)
          Center(
            child: Column(
              children: [
                Text(
                  'Error: ${tiendaState.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                ElevatedButton(
                  onPressed: () => ref
                      .read(tiendaControllerProvider.notifier)
                      .cargarDatosIniciales(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else if (tiendaState.productosDestacados.isEmpty)
          const Center(child: Text('No hay productos disponibles'))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: tiendaState.productosDestacados.length > 4
                ? 4
                : tiendaState.productosDestacados.length,
            itemBuilder: (context, index) {
              final producto = tiendaState.productosDestacados[index];
              return _buildProductCard(
                producto: producto,
                onTap: () => _mostrarDetalleProducto(producto),
              );
            },
          ),
      ],
    );
  }

  // Métodos helper para categorías
  Color _getCategoriaColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'muebles':
        return Colors.brown;
      case 'decoración':
        return Colors.purple;
      case 'cocina':
        return Colors.green;
      case 'dormitorio':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'muebles':
        return Icons.chair;
      case 'decoración':
        return Icons.brush;
      case 'cocina':
        return Icons.kitchen;
      case 'dormitorio':
        return Icons.bed;
      default:
        return Icons.category;
    }
  }

  // Método para mostrar detalle del producto
  void _mostrarDetalleProducto(Producto producto) {
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
              if (producto.color != null) Text('Color: ${producto.color}'),
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
                ref
                    .read(carritoControllerProvider.notifier)
                    .agregarProducto(producto);
                _showSnackBar('Producto agregado al carrito');
              },
              child: const Text('Agregar al Carrito'),
            ),
        ],
      ),
    );
  }

  // Método para construir card de pedido
  Widget _buildPedidoCard(Pedido pedido) {
    Color estadoColor;
    IconData estadoIcon;

    switch (pedido.nombreEstado?.toLowerCase()) {
      case 'pendiente':
        estadoColor = Colors.orange;
        estadoIcon = Icons.pending;
        break;
      case 'confirmado':
        estadoColor = Colors.blue;
        estadoIcon = Icons.check_circle;
        break;
      case 'en_proceso':
        estadoColor = Colors.purple;
        estadoIcon = Icons.settings;
        break;
      case 'enviado':
        estadoColor = Colors.indigo;
        estadoIcon = Icons.local_shipping;
        break;
      case 'entregado':
        estadoColor = Colors.green;
        estadoIcon = Icons.done_all;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${pedido.idPedido}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: estadoColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, color: estadoColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        pedido.nombreEstado ?? 'Desconocido',
                        style: TextStyle(
                          color: estadoColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Fecha: ${_formatearFecha(pedido.fechaCreacion)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              'Total: \$${pedido.total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
            if (pedido.detalles != null && pedido.detalles!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Productos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...pedido.detalles!
                      .take(3)
                      .map(
                        (detalle) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            '• ${detalle.cantidad}x Producto (ID: ${detalle.idProducto})',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  if (pedido.detalles!.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '... y ${pedido.detalles!.length - 3} productos más',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  // Método para construir item del carrito
  Widget _buildCarritoItem(CarritoItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Imagen del producto
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getCategoriaColor(
                  item.producto.categoria,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoriaIcon(item.producto.categoria),
                color: _getCategoriaColor(item.producto.categoria),
                size: 40,
              ),
            ),
            const SizedBox(width: 16),

            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.producto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Precio: \$${item.producto.precio.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Botones de cantidad
                      IconButton(
                        onPressed: () {
                          ref
                              .read(carritoControllerProvider.notifier)
                              .actualizarCantidad(
                                item.producto.idProducto!,
                                item.cantidad - 1,
                              );
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.cantidad}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: item.cantidad < item.producto.stock
                            ? () {
                                ref
                                    .read(carritoControllerProvider.notifier)
                                    .agregarProducto(item.producto);
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Precio total y eliminar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    ref
                        .read(carritoControllerProvider.notifier)
                        .eliminarProducto(item.producto.idProducto!);
                    _showSnackBar('Producto eliminado del carrito');
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // (Obsoleto) Método procesarCompra removido en favor de checkout avanzado.

  // Navegar a pantalla de checkout
  Future<void> _irACheckout() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
    if (result == true) {
      final usuario = ref.read(authControllerProvider).usuario;
      if (usuario != null) {
        setState(() => _selectedIndex = 2);
        ref
            .read(pedidosClienteControllerProvider.notifier)
            .cargarPedidos(usuario.idUsuario!);
      }
    }
  }

  Widget _buildProductCard({
    required Producto producto,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getCategoriaColor(
                    producto.categoria,
                  ).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoriaIcon(producto.categoria),
                      size: 50,
                      color: _getCategoriaColor(producto.categoria),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: producto.tieneStock ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stock: ${producto.stock}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '\$${producto.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarritoTab() {
    final carritoState = ref.watch(carritoControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header con total
          if (carritoState.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: \$${carritoState.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: carritoState.items.isNotEmpty
                        ? _irACheckout
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Comprar'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Lista de productos
          Expanded(
            child: carritoState.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tu carrito está vacío',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega productos desde la tienda',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedIndex = 0),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ir a la Tienda'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: carritoState.items.length,
                    itemBuilder: (context, index) {
                      final item = carritoState.items[index];
                      return _buildCarritoItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosTab() {
    final pedidosState = ref.watch(pedidosClienteControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (pedidosState.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (pedidosState.error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${pedidosState.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final usuario = ref
                            .read(authControllerProvider)
                            .usuario;
                        if (usuario != null) {
                          ref
                              .read(pedidosClienteControllerProvider.notifier)
                              .cargarPedidos(usuario.idUsuario!);
                        }
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (pedidosState.pedidos.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes pedidos aún',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Realiza tu primera compra',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() => _selectedIndex = 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ir a la Tienda'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final usuario = ref.read(authControllerProvider).usuario;
                  if (usuario != null) {
                    await ref
                        .read(pedidosClienteControllerProvider.notifier)
                        .cargarPedidos(usuario.idUsuario!);
                  }
                },
                child: ListView.builder(
                  itemCount: pedidosState.pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidosState.pedidos[index];
                    return _buildPedidoCard(pedido);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerfilTab() {
    final usuario = ref.watch(authControllerProvider).usuario;
    final mode = ref.watch(themeControllerProvider);
    final themeCtrl = ref.read(themeControllerProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            usuario?.nombreCompleto ?? 'Cliente',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            usuario?.nombreRol ?? 'Cliente',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 30),
          // Toggle de tema claro/oscuro
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.brightness_6),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Tema claro / oscuro')),
                  Switch(
                    value: mode == ThemeMode.dark,
                    onChanged: (_) => themeCtrl.toggle(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.edit,
            title: 'Editar Perfil',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilScreen()),
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.location_on,
            title: 'Direcciones',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DireccionesScreen()),
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.payment,
            title: 'Métodos de Pago',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MetodosPagoScreen()),
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.help,
            title: 'Ayuda y Soporte',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AyudaScreen()),
            ),
          ),
          _buildProfileOption(
            icon: Icons.info,
            title: 'Acerca de',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AcercaScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // Opción de perfil reutilizable
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue.shade600),
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Método para mostrar búsqueda
  void _mostrarBusqueda() {
    showSearch(context: context, delegate: ProductoSearchDelegate(ref));
  }

  // Widget para mostrar todos los productos
  Widget _buildTodosLosProductos() {
    final tiendaState = ref.watch(tiendaControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con botón volver y filtros
        Row(
          children: [
            IconButton(
              onPressed: () {
                ref
                    .read(tiendaControllerProvider.notifier)
                    .mostrarProductosDestacados();
              },
              icon: const Icon(Icons.arrow_back),
            ),
            const Expanded(
              child: Text(
                'Todos los Productos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // Filtro por categoría
            if (tiendaState.categorias.isNotEmpty)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.filter_list,
                  color: tiendaState.categoriaSeleccionada != null
                      ? Colors.blue.shade600
                      : Colors.grey.shade600,
                ),
                onSelected: (categoria) {
                  if (categoria == 'todos') {
                    ref
                        .read(tiendaControllerProvider.notifier)
                        .filtrarPorCategoria(null);
                  } else {
                    ref
                        .read(tiendaControllerProvider.notifier)
                        .filtrarPorCategoria(categoria);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'todos',
                    child: Text('Todas las categorías'),
                  ),
                  ...tiendaState.categorias.map(
                    (categoria) =>
                        PopupMenuItem(value: categoria, child: Text(categoria)),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Indicador de categoría seleccionada
        if (tiendaState.categoriaSeleccionada != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt, color: Colors.blue.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Categoría: ${tiendaState.categoriaSeleccionada}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ref
                      .read(tiendaControllerProvider.notifier)
                      .filtrarPorCategoria(null),
                  child: Icon(
                    Icons.close,
                    color: Colors.blue.shade600,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

        // Lista de productos
        if (tiendaState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (tiendaState.error != null)
          Center(
            child: Column(
              children: [
                Text(
                  'Error: ${tiendaState.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(tiendaControllerProvider.notifier)
                      .cargarProductos(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else if (tiendaState.productos.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay productos disponibles',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: tiendaState.productos.length,
            itemBuilder: (context, index) {
              final producto = tiendaState.productos[index];
              return _buildProductCard(
                producto: producto,
                onTap: () => _mostrarDetalleProducto(producto),
              );
            },
          ),
      ],
    );
  }
}
