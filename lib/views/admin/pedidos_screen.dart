import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/pedido.dart';
import '../../models/estado_pedido.dart';
import '../../models/detalle_pedido.dart';
import '../../models/producto.dart';
import '../../models/integracion_entrega.dart';
import '../../services/pedido_service.dart';
import '../../services/producto_service.dart';
import '../../services/auth_service.dart';
import '../../services/integracion_service.dart';
import '../vendedor/nuevo_pedido_screen.dart';

// Providers futuros (TODO): pedidosControllerProvider

class PedidosScreen extends ConsumerStatefulWidget {
  const PedidosScreen({super.key});

  @override
  ConsumerState<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<PedidosScreen> {
  final _service = PedidoService();
  final _integracionService = IntegracionService();
  final List<Pedido> _pedidos = [];
  final List<IntegracionEntrega> _integraciones = [];
  bool _loading = false;
  bool _loadingIntegracion = false;
  bool _mostrarIntegracion = false;
  final DateFormat _fechaFormatter = DateFormat('dd/MM/yyyy HH:mm');
  final TextEditingController _searchCtrl = TextEditingController();
  String _busqueda = '';
  int? _estadoFiltro;
  DateTimeRange? _rangoFechas;

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargarPedidos);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _mostrarIntegracion
                ? _cargarIntegracion
                : _cargarPedidos,
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _toggleIntegracion,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _mostrarIntegracion
                  ? Colors.white24
                  : Colors.transparent,
            ),
            child: const Text('Integración'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _mostrarIntegracion
          ? _buildIntegracionBody()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _pedidos.isEmpty
                  ? _buildEmpty()
                  : Column(
                      children: [
                        _buildFiltros(),
                        Expanded(child: _buildLista()),
                      ],
                    ),
      floatingActionButton: _mostrarIntegracion
          ? null
          : FloatingActionButton(
              onPressed: _crearPedido,
              backgroundColor: Colors.blue.shade800,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No hay pedidos aún'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _crearPedido,
            icon: const Icon(Icons.add),
            label: const Text('Crear Pedido'),
          ),
        ],
      ),
    );
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
              ActionChip(label: const Text('7 dias'), onPressed: () => _aplicarRangoDias(7)),
              ActionChip(label: const Text('30 dias'), onPressed: () => _aplicarRangoDias(30)),
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
            'Sin coincidencias para estos filtros',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarPedidos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, i) {
          final p = data[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _colorEstado(p.idEstado).withValues(alpha: 0.15),
                child: Icon(
                  _iconEstado(p.idEstado),
                  color: _colorEstado(p.idEstado),
                ),
              ),
              title: Text('Pedido #${p.idPedido ?? 'TEMP'}'),
              subtitle: Text(
                '${p.total.toStringAsFixed(2)} | ${p.nombreEstado ?? _nombreEstado(p.idEstado)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _verPedido(p),
            ),
          );
        },
      ),
    );
  }

  Future<void> _cargarPedidos() async {
    try {
      setState(() => _loading = true);
      final pedidos = await _service.obtenerPedidos();
      if (!mounted) return;
      setState(() {
        _pedidos
          ..clear()
          ..addAll(pedidos);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando pedidos: $e')));
    }
  }

  void _crearPedido() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuevoPedidoScreen()),
    ).then((_) => _cargarPedidos());
  }

  void _verPedido(Pedido pedido) {
    if (pedido.idPedido == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PedidoDetalleSheet(idPedido: pedido.idPedido!),
    );
  }

  Color _colorEstado(int idEstado) {
    switch (idEstado) {
      case EstadoPedidoConstants.pendiente:
        return Colors.orange;
      case EstadoPedidoConstants.confirmado:
        return Colors.blue;
      case EstadoPedidoConstants.enviado:
        return Colors.purple;
      case EstadoPedidoConstants.entregado:
        return Colors.green;
      case EstadoPedidoConstants.cancelado:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _iconEstado(int idEstado) {
    switch (idEstado) {
      case EstadoPedidoConstants.pendiente:
        return Icons.hourglass_bottom;
      case EstadoPedidoConstants.confirmado:
        return Icons.work_outline;
      case EstadoPedidoConstants.enviado:
        return Icons.local_shipping;
      case EstadoPedidoConstants.entregado:
        return Icons.check_circle;
      case EstadoPedidoConstants.cancelado:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _nombreEstado(int idEstado) {
    switch (idEstado) {
      case EstadoPedidoConstants.pendiente:
        return EstadoPedidoConstants.pendienteNombre;
      case EstadoPedidoConstants.confirmado:
        return EstadoPedidoConstants.confirmadoNombre;
      case EstadoPedidoConstants.enviado:
        return EstadoPedidoConstants.enviadoNombre;
      case EstadoPedidoConstants.entregado:
        return EstadoPedidoConstants.entregadoNombre;
      case EstadoPedidoConstants.cancelado:
        return EstadoPedidoConstants.canceladoNombre;
      default:
        return 'Desconocido';
    }
  }

  Widget _buildIntegracionBody() {
    if (_loadingIntegracion) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_integraciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text('Sin datos de integraci\u00f3n'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _cargarIntegracion,
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a intentar'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _integraciones.length,
      itemBuilder: (context, i) {
        final entrega = _integraciones[i];
        final total = entrega.precioUnitario * entrega.cantidad;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                entrega.cantidad.toString(),
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            title: Text(entrega.nombreProducto),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: ${entrega.nombreCliente}'),
                Text('Estado: ${entrega.estado}'),
                Text('Fecha: ${_fechaFormatter.format(entrega.fecha)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${entrega.precioUnitario.toStringAsFixed(2)}'),
                Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cargarIntegracion() async {
    setState(() => _loadingIntegracion = true);
    try {
      final data = await _integracionService.obtenerEntregas();
      if (!mounted) return;
      setState(() {
        _integraciones
          ..clear()
          ..addAll(data);
        _loadingIntegracion = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingIntegracion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error integraci\u00f3n: ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  void _toggleIntegracion() {
    setState(() => _mostrarIntegracion = !_mostrarIntegracion);
    if (_mostrarIntegracion && _integraciones.isEmpty) {
      _cargarIntegracion();
    }
  }
}

// Sheet de detalle de pedido
class _PedidoDetalleSheet extends StatefulWidget {
  final int idPedido;
  const _PedidoDetalleSheet({required this.idPedido});
  @override
  State<_PedidoDetalleSheet> createState() => _PedidoDetalleSheetState();
}

class _PedidoDetalleSheetState extends State<_PedidoDetalleSheet> {
  final _service = PedidoService();
  Pedido? _pedido;
  bool _loading = true;
  bool _updating = false;
  List<EstadoPedido> _estados = [];
  int? _estadoSeleccionado;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _service.obtenerPedidoPorId(widget.idPedido);
      final estados = await _service.obtenerEstados();
      if (!mounted) return;
      setState(() {
        _pedido = p;
        _estados = estados;
        _estadoSeleccionado = p?.idEstado;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _actualizarEstado() async {
    if (_pedido == null ||
        _estadoSeleccionado == null ||
        _estadoSeleccionado == _pedido!.idEstado) {
      return;
    }
    setState(() => _updating = true);
    try {
      final actualizado = await _service.actualizarEstadoPedido(
        _pedido!.idPedido!,
        _estadoSeleccionado!,
      );
      if (!mounted) return;
      setState(() {
        _pedido = actualizado;
        _updating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estado actualizado a ${_pedido!.nombreEstado ?? _nombreEstadoLocal(_pedido!.idEstado)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar estado: $e')));
    }
  }

  String _nombreEstadoLocal(int idEstado) {
    switch (idEstado) {
      case EstadoPedidoConstants.pendiente:
        return EstadoPedidoConstants.pendienteNombre;
      case EstadoPedidoConstants.confirmado:
        return EstadoPedidoConstants.confirmadoNombre;
      case EstadoPedidoConstants.enviado:
        return EstadoPedidoConstants.enviadoNombre;
      case EstadoPedidoConstants.entregado:
        return EstadoPedidoConstants.entregadoNombre;
      case EstadoPedidoConstants.cancelado:
        return EstadoPedidoConstants.canceladoNombre;
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: _loading
            ? const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              )
            : _pedido == null
            ? const SizedBox(
                height: 200,
                child: Center(child: Text('Pedido no encontrado')),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${_pedido!.idPedido}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Cliente: ${_pedido!.nombreCliente ?? '-'}'),
                    Row(
                      children: [
                        const Text('Estado:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _estadoSeleccionado,
                            isExpanded: true,
                            items: _estados
                                .map(
                                  (e) => DropdownMenuItem<int>(
                                    value: e.idEstado,
                                    child: Text(e.nombreEstado),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _estadoSeleccionado = v),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              _updating ||
                                  _pedido == null ||
                                  _estadoSeleccionado == _pedido!.idEstado
                              ? null
                              : _actualizarEstado,
                          child: _updating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Actualizar'),
                        ),
                      ],
                    ),
                    Text('Total: \$${_pedido!.total.toStringAsFixed(2)}'),
                    const Divider(height: 32),
                    const Text(
                      'Detalles',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if ((_pedido!.detalles ?? []).isEmpty)
                      const Text('Sin detalles')
                    else
                      ..._pedido!.detalles!.map((d) {
                        final nombre =
                            d.nombreProducto ?? d.skuProducto ?? 'Producto';
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(nombre),
                          subtitle: Text(
                            '${d.cantidad} x \$${d.precioUnitario.toStringAsFixed(2)} (Subtotal: \$${d.subtotal.toStringAsFixed(2)})',
                          ),
                          trailing: Text(
                            '\$${(d.cantidad * d.precioUnitario).toStringAsFixed(2)}',
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

// Sheet de creación de pedido
class _CrearPedidoSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CrearPedidoSheet({required this.onCreated});
  @override
  State<_CrearPedidoSheet> createState() => _CrearPedidoSheetState();
}

class _CrearPedidoSheetState extends State<_CrearPedidoSheet> {
  final _pedidoService = PedidoService();
  final _productoService = ProductoService();
  final _authService = AuthService();
  List<Producto> _productos = [];
  final Map<int, int> _cantidades = {};
  int? _clienteId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prods = await _productoService.obtenerProductos();
      final current = await _authService.getCurrentUserData();
      _clienteId = current
          ?.idUsuario; // Usa usuario actual como cliente (simplificación)
      if (!mounted) return;
      setState(() {
        _productos = prods;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _toggleProducto(Producto p) {
    setState(() {
      if (p.idProducto == null) return;
      if (_cantidades.containsKey(p.idProducto)) {
        _cantidades.remove(p.idProducto);
      } else {
        _cantidades[p.idProducto!] = 1;
      }
    });
  }

  Future<void> _crear() async {
    if (_clienteId == null || _cantidades.isEmpty) return;
    setState(() => _saving = true);
    try {
      final detalles = _cantidades.entries.map((e) {
        final prod = _productos.firstWhere((p) => p.idProducto == e.key);
        return DetallePedido(
          idPedido: 0,
          idProducto: prod.idProducto!,
          cantidad: e.value,
          precioUnitario: prod.precio,
        );
      }).toList();
      await _pedidoService.crearPedido(
        idCliente: _clienteId!,
        detalles: detalles,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creando pedido: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _loading
            ? const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crear Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Cliente: ${_clienteId ?? 'Ninguno'}'),
                    const SizedBox(height: 12),
                    const Text('Productos'),
                    const SizedBox(height: 8),
                    ..._productos.map((p) {
                      final selected =
                          p.idProducto != null &&
                          _cantidades.containsKey(p.idProducto);
                      return Card(
                        child: ListTile(
                          onTap: () => _toggleProducto(p),
                          title: Text(p.nombre),
                          subtitle: Text(
                            'Stock: ${p.stock} • Precio: \$${p.precio.toStringAsFixed(2)}',
                          ),
                          trailing: selected
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          final current =
                                              _cantidades[p.idProducto]!;
                                          if (current > 1) {
                                            _cantidades[p.idProducto!] =
                                                current - 1;
                                          }
                                        });
                                      },
                                    ),
                                    Text(_cantidades[p.idProducto].toString()),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          final current =
                                              _cantidades[p.idProducto]!;
                                          if (current < p.stock) {
                                            _cantidades[p.idProducto!] =
                                                current + 1;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : const Icon(Icons.add_circle_outline),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _crear,
                      icon: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_saving ? 'Creando...' : 'Crear Pedido'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
