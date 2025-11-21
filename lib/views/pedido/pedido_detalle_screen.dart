import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/pedido_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/pedido.dart';
import '../../models/estado_pedido.dart';
import '../../widgets/pedido_timeline.dart';

class PedidoDetalleScreen extends ConsumerStatefulWidget {
  final int idPedido;
  const PedidoDetalleScreen({super.key, required this.idPedido});

  @override
  ConsumerState<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends ConsumerState<PedidoDetalleScreen> {
  bool _loading = true;
  Pedido? _pedido;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Diferir carga para evitar modificar providers durante el ciclo de build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargar();
    });
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final controller = ref.read(pedidoControllerProvider.notifier);
      final auth = ref.read(authControllerProvider);
      Pedido? pedido;

      for (final p in ref.read(pedidoControllerProvider).pedidos) {
        if (p.idPedido == widget.idPedido) {
          pedido = p;
          break;
        }
      }

      if (pedido == null && auth.esAdministrador && ref.read(pedidoControllerProvider).pedidos.isEmpty) {
        await controller.cargarPedidosAdmin();
        for (final p in ref.read(pedidoControllerProvider).pedidos) {
          if (p.idPedido == widget.idPedido) {
            pedido = p;
            break;
          }
        }
      }

      pedido ??= await controller.cargarPedidoPorId(widget.idPedido, forceRefresh: true);

      if (pedido == null) {
        throw Exception('Pedido no encontrado');
      }
      await controller.cargarHistorial(widget.idPedido, forceRefresh: true);
      if (!mounted) return;
      setState(() { _pedido = pedido; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pedidoControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final historial = state.historialCache[widget.idPedido] ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.idPedido}'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _pedido == null
                  ? const Center(child: Text('Pedido no disponible'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente: ${_pedido!.nombreCliente ?? ''}', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Fecha: ${_pedido!.fechaFormateada}'),
                          const SizedBox(height: 4),
                          Text('Total: \$${_pedido!.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(height: 32),
                          PedidoTimeline(historial: historial, estadoActual: _pedido!.idEstado),
                          const Divider(height: 32),
                          Text('Detalles', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (_pedido!.detalles == null || _pedido!.detalles!.isEmpty)
                            const Text('Sin detalles')
                          else
                            ..._pedido!.detalles!.map((d) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(d.nombreProducto ?? d.skuProducto ?? 'Producto ${d.idProducto}'),
                                  subtitle: Text('Cantidad: ${d.cantidad} • Precio: \$${d.precioUnitario.toStringAsFixed(2)}'),
                                  trailing: Text('\$${d.subtotal.toStringAsFixed(2)}'),
                                )),
                          const SizedBox(height: 24),
                          Text('Acciones', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _buildAcciones(context, auth.esAdministrador || auth.esVendedor, auth.esCliente),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildAcciones(BuildContext context, bool puedeGestionar, bool esCliente) {
    if (_pedido == null) return const SizedBox.shrink();
    final idEstado = _pedido!.idEstado;
    final controller = ref.read(pedidoControllerProvider.notifier);
    final List<_ActionCfg> acciones = [];

    void add(int targetEstado, String label, {Color? color}) {
      acciones.add(_ActionCfg(label: label, estado: targetEstado, color: color));
    }

    if (idEstado == EstadoPedidoConstants.pendiente) {
      if (puedeGestionar) add(EstadoPedidoConstants.confirmado, 'Confirmar');
      if (puedeGestionar || esCliente) add(EstadoPedidoConstants.cancelado, 'Cancelar', color: Colors.red);
    } else if (idEstado == EstadoPedidoConstants.confirmado) {
      if (puedeGestionar) add(EstadoPedidoConstants.enviado, 'Marcar Enviado');
      if (puedeGestionar) add(EstadoPedidoConstants.cancelado, 'Cancelar', color: Colors.red);
    } else if (idEstado == EstadoPedidoConstants.enviado) {
      if (puedeGestionar) add(EstadoPedidoConstants.entregado, 'Marcar Entregado');
      if (puedeGestionar) add(EstadoPedidoConstants.cancelado, 'Cancelar', color: Colors.red);
    }

    if (acciones.isEmpty) {
      return const Text('No hay acciones disponibles');
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: acciones.map((a) {
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: a.color,
          ),
          onPressed: () async {
            final ok = await controller.cambiarEstado(_pedido!.idPedido!, a.estado);
            if (!context.mounted) return;
            if (ok) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estado actualizado a ${a.label}')));
              await _cargar();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cambiar estado')));
            }
          },
          icon: const Icon(Icons.sync),
          label: Text(a.label),
        );
      }).toList(),
    );
  }
}

class _ActionCfg {
  final String label;
  final int estado;
  final Color? color;
  _ActionCfg({required this.label, required this.estado, this.color});
}
