import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart';
import '../models/pedido.dart';
import '../services/cliente_service.dart';

// Estado para la tienda del cliente
class TiendaState {
  final List<Producto> productos;
  final List<Producto> productosDestacados;
  final List<String> categorias;
  final bool isLoading;
  final String? error;
  final String? categoriaSeleccionada;
  final String? searchQuery;
  final bool mostrarTodosLosProductos;

  TiendaState({
    this.productos = const [],
    this.productosDestacados = const [],
    this.categorias = const [],
    this.isLoading = false,
    this.error,
    this.categoriaSeleccionada,
    this.searchQuery,
    this.mostrarTodosLosProductos = false,
  });

  TiendaState copyWith({
    List<Producto>? productos,
    List<Producto>? productosDestacados,
    List<String>? categorias,
    bool? isLoading,
    String? error,
    String? categoriaSeleccionada,
    String? searchQuery,
    bool? mostrarTodosLosProductos,
  }) {
    return TiendaState(
      productos: productos ?? this.productos,
      productosDestacados: productosDestacados ?? this.productosDestacados,
      categorias: categorias ?? this.categorias,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      categoriaSeleccionada: categoriaSeleccionada ?? this.categoriaSeleccionada,
      searchQuery: searchQuery ?? this.searchQuery,
      mostrarTodosLosProductos: mostrarTodosLosProductos ?? this.mostrarTodosLosProductos,
    );
  }
}

// Estado para pedidos del cliente
class PedidosClienteState {
  final List<Pedido> pedidos;
  final bool isLoading;
  final String? error;

  PedidosClienteState({
    this.pedidos = const [],
    this.isLoading = false,
    this.error,
  });

  PedidosClienteState copyWith({
    List<Pedido>? pedidos,
    bool? isLoading,
    String? error,
  }) {
    return PedidosClienteState(
      pedidos: pedidos ?? this.pedidos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Estado del carrito
class CarritoItem {
  final Producto producto;
  final int cantidad;

  CarritoItem({
    required this.producto,
    required this.cantidad,
  });

  CarritoItem copyWith({
    Producto? producto,
    int? cantidad,
  }) {
    return CarritoItem(
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  double get subtotal => producto.precio * cantidad;
}

class CarritoState {
  final List<CarritoItem> items;
  final bool isLoading;
  final String? error;

  CarritoState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  CarritoState copyWith({
    List<CarritoItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return CarritoState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get cantidadTotal => items.fold(0, (sum, item) => sum + item.cantidad);
}

// Controller para la tienda
class TiendaController extends StateNotifier<TiendaState> {
  final ClienteService _clienteService;

  TiendaController(this._clienteService) : super(TiendaState());

  Future<void> cargarDatosIniciales() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final futures = await Future.wait([
        _clienteService.obtenerProductosDestacados(),
        _clienteService.obtenerCategorias(),
      ]);

      state = state.copyWith(
        productosDestacados: futures[0] as List<Producto>,
        categorias: futures[1] as List<String>,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> cargarProductos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final productos = await _clienteService.obtenerProductosTienda();
      state = state.copyWith(
        productos: productos,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> filtrarPorCategoria(String? categoria) async {
    state = state.copyWith(
      isLoading: true,
      categoriaSeleccionada: categoria,
      mostrarTodosLosProductos: true, // ir a vista de todos al filtrar
    );
    try {
      final productos = categoria == null
          ? await _clienteService.obtenerProductosTienda()
          : await _clienteService.obtenerProductosPorCategoria(categoria);
      
      state = state.copyWith(
        productos: productos,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> buscarProductos(String query) async {
    state = state.copyWith(isLoading: true, searchQuery: query);
    try {
      final productos = query.isEmpty
          ? await _clienteService.obtenerProductosTienda()
          : await _clienteService.buscarProductos(query);
      
      state = state.copyWith(
        productos: productos,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void mostrarTodosLosProductos() {
    state = state.copyWith(mostrarTodosLosProductos: true, categoriaSeleccionada: null);
    cargarProductos(); // Cargar todos los productos
  }

  void mostrarProductosDestacados() {
    state = state.copyWith(mostrarTodosLosProductos: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Controller para pedidos del cliente
class PedidosClienteController extends StateNotifier<PedidosClienteState> {
  final ClienteService _clienteService;

  PedidosClienteController(this._clienteService) : super(PedidosClienteState());

  Future<void> cargarPedidos(int idCliente) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pedidos = await _clienteService.obtenerPedidosCliente(idCliente);
      state = state.copyWith(
        pedidos: pedidos,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Controller para el carrito
class CarritoController extends StateNotifier<CarritoState> {
  final ClienteService _clienteService;

  CarritoController(this._clienteService) : super(CarritoState());

  void agregarProducto(Producto producto, {int cantidad = 1}) {
    final items = List<CarritoItem>.from(state.items);
    
    // Verificar si el producto ya está en el carrito
    final existingIndex = items.indexWhere((item) => item.producto.idProducto == producto.idProducto);
    
    if (existingIndex >= 0) {
      // Actualizar cantidad
      final nuevaCantidad = items[existingIndex].cantidad + cantidad;
      if (nuevaCantidad <= producto.stock) {
        items[existingIndex] = items[existingIndex].copyWith(cantidad: nuevaCantidad);
      }
    } else {
      // Agregar nuevo item
      if (cantidad <= producto.stock) {
        items.add(CarritoItem(producto: producto, cantidad: cantidad));
      }
    }
    
    state = state.copyWith(items: items);
  }

  void actualizarCantidad(int idProducto, int nuevaCantidad) {
    final items = List<CarritoItem>.from(state.items);
    final index = items.indexWhere((item) => item.producto.idProducto == idProducto);
    
    if (index >= 0) {
      if (nuevaCantidad <= 0) {
        items.removeAt(index);
      } else if (nuevaCantidad <= items[index].producto.stock) {
        items[index] = items[index].copyWith(cantidad: nuevaCantidad);
      }
    }
    
    state = state.copyWith(items: items);
  }

  void eliminarProducto(int idProducto) {
    final items = state.items.where((item) => item.producto.idProducto != idProducto).toList();
    state = state.copyWith(items: items);
  }

  void limpiarCarrito() {
    state = state.copyWith(items: []);
  }

  Future<bool> procesarPedido(int idCliente) async {
    if (state.items.isEmpty) return false;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final itemsPedido = state.items.map((item) => {
        'id_producto': item.producto.idProducto!,
        'cantidad': item.cantidad,
        'precio_unitario': item.producto.precio,
      }).toList();

      await _clienteService.crearPedido(
        idCliente: idCliente,
        items: itemsPedido,
        total: state.total,
      );

      state = state.copyWith(items: [], isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> procesarPedidoAvanzado({
    required int idCliente,
    required String tipoEntrega, // 'envio' | 'retiro'
    String? direccionEnvio,
    required String metodoPago, // 'tarjeta' | 'transferencia' | 'efectivo'
    String? pagoReferencia,
  }) async {
    if (state.items.isEmpty) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final itemsPedido = state.items.map((item) => {
        'id_producto': item.producto.idProducto!,
        'cantidad': item.cantidad,
        'precio_unitario': item.producto.precio,
      }).toList();

      await _clienteService.crearPedidoAvanzado(
        idCliente: idCliente,
        items: itemsPedido,
        total: state.total,
        tipoEntrega: tipoEntrega,
        direccionEnvio: direccionEnvio,
        metodoPago: metodoPago,
        pagoReferencia: pagoReferencia,
      );

      state = state.copyWith(items: [], isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final clienteServiceProvider = Provider<ClienteService>((ref) => ClienteService());

final tiendaControllerProvider = StateNotifierProvider<TiendaController, TiendaState>((ref) {
  final clienteService = ref.watch(clienteServiceProvider);
  return TiendaController(clienteService);
});

final pedidosClienteControllerProvider = StateNotifierProvider<PedidosClienteController, PedidosClienteState>((ref) {
  final clienteService = ref.watch(clienteServiceProvider);
  return PedidosClienteController(clienteService);
});

final carritoControllerProvider = StateNotifierProvider<CarritoController, CarritoState>((ref) {
  final clienteService = ref.watch(clienteServiceProvider);
  return CarritoController(clienteService);
});
