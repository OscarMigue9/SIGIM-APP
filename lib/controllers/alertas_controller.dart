import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/producto_service.dart';
import '../services/pedido_service.dart';

class AlertasState {
  final int stockBajo;
  final int pedidosPendientes;
  final bool loading;
  final String? error;

  AlertasState({
    this.stockBajo = 0,
    this.pedidosPendientes = 0,
    this.loading = false,
    this.error,
  });

  AlertasState copyWith({
    int? stockBajo,
    int? pedidosPendientes,
    bool? loading,
    String? error,
  }) => AlertasState(
        stockBajo: stockBajo ?? this.stockBajo,
        pedidosPendientes: pedidosPendientes ?? this.pedidosPendientes,
        loading: loading ?? this.loading,
        error: error,
      );
}

class AlertasController extends StateNotifier<AlertasState> {
  final ProductoService _productoService;
  final PedidoService _pedidoService;
  AlertasController(this._productoService, this._pedidoService) : super(AlertasState()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final productosBajo = await _productoService.obtenerProductosConStockBajo(limite: 10);
      final pedidos = await _pedidoService.obtenerPedidos();
      final pendientes = pedidos.where((p) => p.idEstado == 1).length;
      state = state.copyWith(
        stockBajo: productosBajo.length,
        pedidosPendientes: pendientes,
        loading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final productoServiceProvider2 = Provider<ProductoService>((ref) => ProductoService());
final pedidoServiceProvider2 = Provider<PedidoService>((ref) => PedidoService());

final alertasControllerProvider = StateNotifierProvider<AlertasController, AlertasState>((ref) {
  final prod = ref.watch(productoServiceProvider2);
  final ped = ref.watch(pedidoServiceProvider2);
  return AlertasController(prod, ped);
});