import 'package:flutter/material.dart';
import '../models/pedido_historial.dart';
import '../models/estado_pedido.dart';

class PedidoTimeline extends StatelessWidget {
  final List<PedidoHistorial> historial;
  final int estadoActual;
  const PedidoTimeline({super.key, required this.historial, required this.estadoActual});

  static const _estadosOrden = [
    EstadoPedidoConstants.pendiente,
    EstadoPedidoConstants.confirmado,
    EstadoPedidoConstants.enviado,
    EstadoPedidoConstants.entregado,
    EstadoPedidoConstants.cancelado,
  ];

  String _nombreEstado(int id) {
    switch (id) {
      case EstadoPedidoConstants.pendiente: return EstadoPedidoConstants.pendienteNombre;
      case EstadoPedidoConstants.confirmado: return EstadoPedidoConstants.confirmadoNombre;
      case EstadoPedidoConstants.enviado: return EstadoPedidoConstants.enviadoNombre;
      case EstadoPedidoConstants.entregado: return EstadoPedidoConstants.entregadoNombre;
      case EstadoPedidoConstants.cancelado: return EstadoPedidoConstants.canceladoNombre;
      default: return 'Estado $id';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Mapear historial por estado
    final mapHistorial = <int, PedidoHistorial>{};
    for (final h in historial) {
      mapHistorial[h.idEstado] = h; // último para cada estado
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historial', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._estadosOrden.map((estado) {
          final h = mapHistorial[estado];
          final reached = h != null || estado == estadoActual;
          final active = estado == estadoActual;
          final cancelled = estado == EstadoPedidoConstants.cancelado && reached;
          final color = cancelled
              ? Colors.red
              : active
                  ? theme.colorScheme.primary
                  : reached
                      ? theme.colorScheme.secondary
                      : Colors.grey;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    cancelled ? Icons.cancel : Icons.check_circle,
                    color: color,
                    size: 20,
                  ),
                  if (estado != _estadosOrden.last)
                    Container(
                      width: 2,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombreEstado(estado),
                        style: TextStyle(
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          color: color,
                        ),
                      ),
                      if (h != null)
                        Text(
                          _formatFecha(h.fecha),
                          style: theme.textTheme.bodySmall,
                        ),
                      if (h?.comentario != null)
                        Text(
                          h!.comentario!,
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  String _formatFecha(DateTime dt) => '${_two(dt.day)}/${_two(dt.month)}/${dt.year} ${_two(dt.hour)}:${_two(dt.minute)}';
  String _two(int v) => v.toString().padLeft(2, '0');
}
