import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../services/pedido_service.dart';
import '../../models/pedido.dart';
import '../../models/estado_pedido.dart';
import 'nuevo_pedido_screen.dart';
import '../pedido/pedido_detalle_screen.dart';

class PedidosVendedorScreen extends ConsumerStatefulWidget {
  const PedidosVendedorScreen({super.key});

  @override
  ConsumerState<PedidosVendedorScreen> createState() => _PedidosVendedorScreenState();
}

class _PedidosVendedorScreenState extends ConsumerState<PedidosVendedorScreen> {
  final _service = PedidoService();
  bool _loading = true;
  List<Pedido> _pedidos = [];
  String? _error;
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
      // Intentar cargar pedidos filtrados por vendedor
      var pedidos = await _service.obtenerPedidosVendedor(user!.idUsuario!);
      // Si no hay soporte de columna id_vendedor, mostrar todos como fallback informativo
      if (pedidos.isEmpty) {
        pedidos = await _service.obtenerPedidos();
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
        final matchQuery = (p.nombreCliente ?? '').toLowerCase().contains(query) ||
            (p.nombreEstado ?? '').toLowerCase().contains(query) ||
            (p.idPedido?.toString().contains(query) ?? false) ||
            (p.metodoPago ?? '').toLowerCase().contains(query);
        if (!matchQuery) return false;
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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

  Widget _buildListaFiltrada() {
    final data = _pedidosFiltrados;
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Sin pedidos para estos filtros',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = data[i];
        return ListTile(
          leading: CircleAvatar(child: Text(p.idPedido?.toString() ?? '?')),
          title: Text('Pedido #${p.idPedido ?? '-'} | ${p.nombreCliente ?? ''}'),
          subtitle: Text('${p.fechaFormateada} | ${p.nombreEstado ?? ''}'),
          trailing: Text('\$${p.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PedidoDetalleScreen(idPedido: p.idPedido!),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _pedidos.isEmpty
                  ? const Center(child: Text('Sin pedidos'))
                  : Column(
                      children: [
                        _buildFiltros(),
                        Expanded(child: _buildListaFiltrada()),
                      ],
                    ),
    );
  }
}

