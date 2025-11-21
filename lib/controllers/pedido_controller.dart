import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pedido.dart';
import '../models/detalle_pedido.dart';
import '../models/pedido_historial.dart';
import '../services/pedido_service.dart';

class PedidoState {
  final List<Pedido> pedidos;
  final bool isLoading;
  final String? error;
  final Map<int, List<PedidoHistorial>> historialCache;

  PedidoState({
    this.pedidos = const [],
    this.isLoading = false,
    this.error,
    this.historialCache = const {},
  });

  PedidoState copyWith({
    List<Pedido>? pedidos,
    bool? isLoading,
    String? error,
    Map<int, List<PedidoHistorial>>? historialCache,
  }) {
    return PedidoState(
      pedidos: pedidos ?? this.pedidos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      historialCache: historialCache ?? this.historialCache,
    );
  }
}

class PedidoController extends StateNotifier<PedidoState> {
  final PedidoService _pedidoService;

  PedidoController(this._pedidoService) : super(PedidoState());

  Future<void> cargarPedidosAdmin() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pedidos = await _pedidoService.obtenerPedidos();
      state = state.copyWith(pedidos: pedidos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> crearPedidoBasico({
    required int idCliente,
    required List<DetallePedido> detalles,
    int? idVendedor,
  }) async {
    try {
      final nuevo = await _pedidoService.crearPedido(
        idCliente: idCliente,
        idVendedor: idVendedor,
        detalles: detalles,
      );
      state = state.copyWith(pedidos: [nuevo, ...state.pedidos]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> cambiarEstado(int idPedido, int nuevoEstado) async {
    try {
      final actualizado = await _pedidoService.actualizarEstadoPedido(idPedido, nuevoEstado);
      final lista = state.pedidos.map((p) => p.idPedido == actualizado.idPedido ? actualizado : p).toList();
      state = state.copyWith(pedidos: lista);
      await cargarHistorial(idPedido, forceRefresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<Pedido?> cargarPedidoPorId(int idPedido, {bool forceRefresh = false}) async {
    try {
      Pedido? pedido;
      if (!forceRefresh) {
        for (final p in state.pedidos) {
          if (p.idPedido == idPedido) {
            pedido = p;
            break;
          }
        }
      }
      pedido ??= await _pedidoService.obtenerPedidoPorId(idPedido);
      if (pedido != null) {
        final lista = [...state.pedidos];
        final idx = lista.indexWhere((p) => p.idPedido == idPedido);
        if (idx >= 0) {
          lista[idx] = pedido;
        } else {
          lista.insert(0, pedido);
        }
        state = state.copyWith(pedidos: lista);
      }
      return pedido;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<void> cargarHistorial(int idPedido, {bool forceRefresh = false}) async {
    if (!forceRefresh && state.historialCache.containsKey(idPedido)) return;
    try {
      final historial = await _pedidoService.obtenerHistorialPedido(idPedido);
      final nuevoCache = Map<int, List<PedidoHistorial>>.from(state.historialCache);
      nuevoCache[idPedido] = historial;
      state = state.copyWith(historialCache: nuevoCache);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final pedidoServiceProvider = Provider<PedidoService>((ref) => PedidoService());

final pedidoControllerProvider = StateNotifierProvider<PedidoController, PedidoState>((ref) {
  final service = ref.watch(pedidoServiceProvider);
  return PedidoController(service);
});
