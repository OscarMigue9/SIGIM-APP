import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart';
import '../services/ajuste_inventario_service.dart';
import '../services/producto_service.dart';

// Estado de productos
class ProductoState {
  final List<Producto> productos;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? categoriaSeleccionada;
  final int? minStock;
  final int? maxStock;

  ProductoState({
    this.productos = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.categoriaSeleccionada,
    this.minStock,
    this.maxStock,
  });

  ProductoState copyWith({
    List<Producto>? productos,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? categoriaSeleccionada,
    int? minStock,
    int? maxStock,
  }) {
    return ProductoState(
      productos: productos ?? this.productos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      categoriaSeleccionada:
          categoriaSeleccionada ?? this.categoriaSeleccionada,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
    );
  }

  List<Producto> get productosConStock =>
      productos.where((p) => p.tieneStock).toList();

  List<Producto> get productosStockBajo =>
      productos.where((p) => p.stockBajo).toList();

  List<Producto> get productosFiltradosPorStock {
    return productos.where((p) {
      final cumpleMin = minStock == null ? true : p.stock >= minStock!;
      final cumpleMax = maxStock == null ? true : p.stock <= maxStock!;
      return cumpleMin && cumpleMax;
    }).toList();
  }
}

// Controller de productos
class ProductoController extends StateNotifier<ProductoState> {
  final ProductoService _productoService;
  final AjusteInventarioService _ajusteService;

  ProductoController(this._productoService, this._ajusteService)
    : super(ProductoState());

  Future<void> cargarProductos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final productos = await _productoService.obtenerProductos();
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
          ? await _productoService.obtenerProductos()
          : await _productoService.buscarProductos(query);
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
    state = state.copyWith(isLoading: true, categoriaSeleccionada: categoria);
    try {
      final productos = categoria == null
          ? await _productoService.obtenerProductos()
          : await _productoService.obtenerProductosPorCategoria(categoria);
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

  Future<bool> crearProducto(Producto producto) async {
    try {
      final nuevoProducto = await _productoService.crearProducto(producto);
      final productosActuales = [...state.productos, nuevoProducto];
      state = state.copyWith(productos: productosActuales);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> actualizarProducto(Producto producto) async {
    try {
      final productoActualizado = await _productoService.actualizarProducto(
        producto,
      );
      final productosActuales = state.productos.map((p) {
        return p.idProducto == productoActualizado.idProducto
            ? productoActualizado
            : p;
      }).toList();
      state = state.copyWith(productos: productosActuales);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> eliminarProducto(int idProducto) async {
    try {
      await _productoService.eliminarProducto(idProducto);
      final productosActuales = state.productos
          .where((p) => p.idProducto != idProducto)
          .toList();
      state = state.copyWith(productos: productosActuales);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> cargarProductosStockBajo() async {
    state = state.copyWith(isLoading: true);
    try {
      final productos = await _productoService.obtenerProductosConStockBajo();
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

  Future<bool> actualizarStock(int idProducto, int nuevoStock) async {
    try {
      await _productoService.actualizarStock(idProducto, nuevoStock);
      await cargarProductos(); // Recargar lista
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setStockRange({int? min, int? max}) {
    state = state.copyWith(minStock: min, maxStock: max);
  }

  Future<bool> aplicarAjusteInventario({
    required int idProducto,
    required int nuevoStock,
    required String motivo,
  }) async {
    try {
      final productoActual = state.productos.firstWhere(
        (p) => p.idProducto == idProducto,
        orElse: () => throw Exception('Producto no encontrado en memoria'),
      );

      final delta = nuevoStock - productoActual.stock;
      if (delta == 0) {
        throw Exception('El stock no cambió');
      }
      if (motivo.trim().isEmpty) {
        throw Exception('Motivo requerido');
      }

      final ajuste = await _ajusteService.aplicarAjuste(
        idProducto: idProducto,
        delta: delta,
        motivo: motivo,
      );

      // Actualizar la lista local con el nuevo stock
      final productosActualizados = state.productos.map((p) {
        if (p.idProducto == idProducto) {
          return Producto(
            idProducto: p.idProducto,
            sku: p.sku,
            nombre: p.nombre,
            categoria: p.categoria,
            dimensiones: p.dimensiones,
            material: p.material,
            color: p.color,
            precio: p.precio,
            costo: p.costo,
            stock: ajuste.stockFinal,
          );
        }
        return p;
      }).toList();

      state = state.copyWith(productos: productosActualizados, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

// Providers
final productoServiceProvider = Provider<ProductoService>(
  (ref) => ProductoService(),
);
final ajusteInventarioServiceProvider = Provider<AjusteInventarioService>(
  (ref) => AjusteInventarioService(),
);

final productoControllerProvider =
    StateNotifierProvider<ProductoController, ProductoState>((ref) {
      final productoService = ref.watch(productoServiceProvider);
      final ajusteService = ref.watch(ajusteInventarioServiceProvider);
      return ProductoController(productoService, ajusteService);
    });

final categoriasProvider = FutureProvider<List<String>>((ref) async {
  final productoService = ref.watch(productoServiceProvider);
  return await productoService.obtenerCategorias();
});

final productosStockBajoProvider = FutureProvider<List<Producto>>((ref) async {
  final productoService = ref.watch(productoServiceProvider);
  return await productoService.obtenerProductosConStockBajo();
});
