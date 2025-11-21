import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../services/pedido_service.dart';
import 'nuevo_pedido_screen.dart';
import '../../models/pedido.dart';
import '../../models/estado_pedido.dart';

class VentasVendedorScreen extends ConsumerStatefulWidget {
  const VentasVendedorScreen({super.key});

  @override
  ConsumerState<VentasVendedorScreen> createState() => _VentasVendedorScreenState();
}

class _VentasVendedorScreenState extends ConsumerState<VentasVendedorScreen> {
  final _pedidoService = PedidoService();
  bool _loading = true;
  List<Pedido> _pedidos = [];
  String? _error;
  bool _fallbackAll = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _busqueda = '';
  int? _estadoFiltro;
  DateTimeRange? _rangoFechas;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = ref.read(authControllerProvider).usuario;
      if (user?.idUsuario == null) throw Exception('Usuario no autenticado');
      // Cargar pedidos del vendedor vía servicio principal
      var pedidos = await _pedidoService.obtenerPedidosVendedor(user!.idUsuario!);
      // Fallback: si no hay resultados (p.ej. pedidos históricos sin id_vendedor), mostrar todos y marcar aviso
      _fallbackAll = false;
      if (pedidos.isEmpty) {
        final todos = await _pedidoService.obtenerPedidos();
        if (todos.isNotEmpty) {
          pedidos = todos;
          _fallbackAll = true;
        }
      }
      setState(() { _pedidos = pedidos; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Pedido> get _pedidosFiltrados {
    return _pedidos.where((p) {
      final query = _busqueda.trim().toLowerCase();
      if (query.isNotEmpty) {
        final match = (p.nombreCliente ?? '').toLowerCase().contains(query) ||
            (p.nombreEstado ?? '').toLowerCase().contains(query) ||
            (p.idPedido?.toString().contains(query) ?? false) ||
            (p.metodoPago ?? '').toLowerCase().contains(query);
        if (!match) return false;
      }
      if (_estadoFiltro != null && p.idEstado != _estadoFiltro) return false;
      if (_rangoFechas != null) {
        final start = DateTime(_rangoFechas!.start.year, _rangoFechas!.start.month, _rangoFechas!.start.day);
        final end = DateTime(_rangoFechas!.end.year, _rangoFechas!.end.month, _rangoFechas!.end.day, 23, 59, 59);
        if (p.fechaCreacion.isBefore(start) || p.fechaCreacion.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  void _aplicarRangoDias(int dias) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = end.subtract(Duration(days: dias - 1));
    setState(() => _rangoFechas = DateTimeRange(start: start, end: end));
  }

  Future<void> _seleccionarRangoManual() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _rangoFechas ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 6)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() => _rangoFechas = picked);
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _busqueda = '';
      _estadoFiltro = null;
      _rangoFechas = null;
      _searchCtrl.clear();
    });
  }

  String get _rangoLabel {
    if (_rangoFechas == null) return '';
    final start = _rangoFechas!.start;
    final end = _rangoFechas!.end;
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar por cliente, estado o #',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _limpiarFiltros,
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _busqueda = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _estadoFiltro,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: EstadoPedidoConstants.pendiente, child: Text('Pendiente')),
                    DropdownMenuItem(value: EstadoPedidoConstants.confirmado, child: Text('Confirmado')),
                    DropdownMenuItem(value: EstadoPedidoConstants.enviado, child: Text('Enviado')),
                    DropdownMenuItem(value: EstadoPedidoConstants.entregado, child: Text('Entregado')),
                    DropdownMenuItem(value: EstadoPedidoConstants.cancelado, child: Text('Cancelado')),
                  ],
                  onChanged: (v) => setState(() => _estadoFiltro = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _seleccionarRangoManual,
                  icon: const Icon(Icons.date_range),
                  label: Text(_rangoFechas == null ? 'Rango de fechas' : _rangoLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ActionChip(label: const Text('Hoy'), onPressed: () => _aplicarRangoDias(1)),
              ActionChip(label: const Text('7 d\u00edas'), onPressed: () => _aplicarRangoDias(7)),
              ActionChip(label: const Text('30 d\u00edas'), onPressed: () => _aplicarRangoDias(30)),
              if (_rangoFechas != null)
                InputChip(
                  label: Text('Activo: $_rangoLabel'),
                  onDeleted: () => setState(() => _rangoFechas = null),
                ),
              if (_busqueda.isNotEmpty || _estadoFiltro != null || _rangoFechas != null)
                ActionChip(
                  label: const Text('Limpiar filtros'),
                  onPressed: _limpiarFiltros,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    final data = _pedidosFiltrados;
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Sin ventas para estos filtros',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: data.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = data[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _colorEstado(p.idEstado).withValues(alpha: 0.15),
            child: Icon(_iconEstado(p.idEstado), color: _colorEstado(p.idEstado)),
          ),
          title: Text('Pedido #${p.idPedido ?? '-'}'),
          subtitle: Text('${p.nombreCliente ?? ''} | ${p.nombreEstado ?? _nombreEstado(p.idEstado)}${p.metodoPago != null ? ' | ${p.metodoPago}' : ''}'),
          trailing: Text('\$${p.total.toStringAsFixed(2)}'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas del Vendedor'),
        actions: [IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _pedidos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.point_of_sale, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text('Sin ventas aun', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text(
                              'Si acabas de habilitar ventas por vendedor, crea un nuevo pedido para verlo aqui.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const NuevoPedidoScreen()),
                                );
                                if (mounted) _cargar();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Crear pedido'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: Column(
                        children: [
                          if (_fallbackAll)
                            Container(
                              width: double.infinity,
                              color: Colors.amber.withValues(alpha: 0.15),
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Mostrando todas las ventas (pedidos antiguos sin id_vendedor). Crea un nuevo pedido para ver tus ventas asociadas.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          _buildFiltros(),
                          Expanded(child: _buildLista()),
                        ],
                      ),
                    ),
    );
  }

  Color _colorEstado(int idEstado) {
    switch (idEstado) {
      case EstadoPedidoConstants.pendiente: return Colors.orange;
      case EstadoPedidoConstants.confirmado: return Colors.blue;
      case EstadoPedidoConstants.enviado: return Colors.purple;
      case EstadoPedidoConstants.entregado: return Colors.green;
      case EstadoPedidoConstants.cancelado: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _iconEstado(int idEstado) {
    switch (idEstado) {
      case EstadoPedidoConstants.pendiente: return Icons.hourglass_bottom;
      case EstadoPedidoConstants.confirmado: return Icons.work_outline;
      case EstadoPedidoConstants.enviado: return Icons.local_shipping;
      case EstadoPedidoConstants.entregado: return Icons.check_circle;
      case EstadoPedidoConstants.cancelado: return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  String _nombreEstado(int idEstado) {
    switch (idEstado) {
      case EstadoPedidoConstants.pendiente: return EstadoPedidoConstants.pendienteNombre;
      case EstadoPedidoConstants.confirmado: return EstadoPedidoConstants.confirmadoNombre;
      case EstadoPedidoConstants.enviado: return EstadoPedidoConstants.enviadoNombre;
      case EstadoPedidoConstants.entregado: return EstadoPedidoConstants.entregadoNombre;
      case EstadoPedidoConstants.cancelado: return EstadoPedidoConstants.canceladoNombre;
      default: return 'Desconocido';
    }
  }
}
