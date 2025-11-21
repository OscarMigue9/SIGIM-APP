import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/pedido_service.dart';
import '../../services/usuario_service.dart';
import '../../services/cliente_contacto_service.dart';
import '../../controllers/producto_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/detalle_pedido.dart';

class NuevoPedidoScreen extends ConsumerStatefulWidget {
  const NuevoPedidoScreen({super.key});

  @override
  ConsumerState<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}

class _NuevoPedidoScreenState extends ConsumerState<NuevoPedidoScreen> {
  final _pedidoService = PedidoService();
  final _usuarioService = UsuarioService();
  final _contactoService = ClienteContactoService();
  final List<DetallePedido> _detalles = [];
  bool _loading = false;
  int? _clienteSeleccionado;
  List<Map<String, dynamic>> _clientes = []; // {id, nombre, contacto:boolean}
  String? _error;
  bool _creandoCliente = false;
  final _codigoDescCtrl = TextEditingController();
  final TextEditingController _clienteSearchCtrl = TextEditingController();
  final TextEditingController _productoSearchCtrl = TextEditingController();
  String _clienteFiltro = '';
  String _productoFiltro = '';
  bool _soloStock = false;
  String _metodoPago = 'efectivo';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
    Future.microtask(() => ref.read(productoControllerProvider.notifier).cargarProductos());
  }

  @override
  void dispose() {
    _codigoDescCtrl.dispose();
    _clienteSearchCtrl.dispose();
    _productoSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    try {
      final clientes = await _usuarioService.obtenerClientes();
      setState(() {
        _clientes = clientes.map((c) => {'id': c.idUsuario, 'nombre': '${c.nombre} ${c.apellido}', 'contacto': false}).toList();
      });
    } catch (e) {
      setState(() { _error = 'Error cargando clientes'; });
    }
  }

  Future<void> _crearClienteRapido() async {
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final navigator = Navigator.of(context);

    final creado = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo Cliente (registro interno)'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: apellidoCtrl,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo (opcional)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // opcional
                  final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!r.hasMatch(v.trim())) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text('No se asignará contraseña ni cuenta de acceso. Uso interno para pedidos.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  setState(() => _creandoCliente = true);
                  try {
                // Si no se proporciona correo, generar placeholder único
                String? email = emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim();
                email ??= '${nombreCtrl.text.trim().toLowerCase()}.${apellidoCtrl.text.trim().toLowerCase()}.${DateTime.now().millisecondsSinceEpoch}@placeholder.local';
                final nuevo = await _contactoService.crearContacto(
                  nombre: nombreCtrl.text.trim(),
                  apellido: apellidoCtrl.text.trim(),
                  email: email,
                );
                if (!mounted) return;
                navigator.pop({
                  'id': nuevo['id_cliente'],
                  'nombre': '${nuevo['nombre']} ${nuevo['apellido']}',
                  'contacto': true,
                });
                  } catch (e) {
                    _showSnack('Error creando cliente: ${e.toString().replaceAll('Exception: ', '')}');
                    navigator.pop();
                  } finally {
                    if (mounted) setState(() => _creandoCliente = false);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (creado != null) {
      setState(() {
        _clientes.insert(0, creado);
        _clienteSeleccionado = creado['id'] as int?;
      });
      _showSnack('Cliente creado y seleccionado');
    }
  }

  List<Map<String, dynamic>> get _clientesFiltrados {
    final query = _clienteFiltro.toLowerCase();
    final filtrados = _clientes.where((c) {
      final nombre = (c['nombre'] as String?)?.toLowerCase() ?? '';
      if (query.isNotEmpty && !nombre.contains(query)) return false;
      return true;
    }).toList();
    if (_clienteSeleccionado != null && filtrados.every((c) => c['id'] != _clienteSeleccionado)) {
      final actual = _clientes.firstWhere(
        (c) => c['id'] == _clienteSeleccionado,
        orElse: () => <String, dynamic>{},
      );
      if (actual.isNotEmpty) filtrados.insert(0, actual);
    }
    return filtrados;
  }

  void _agregarProducto(int idProducto, double precio, String nombre) {
    final existenteIndex = _detalles.indexWhere((d) => d.idProducto == idProducto);
    setState(() {
      if (existenteIndex >= 0) {
        final existente = _detalles[existenteIndex];
        _detalles[existenteIndex] = DetallePedido(
          idPedido: existente.idPedido,
          idProducto: existente.idProducto,
          cantidad: existente.cantidad + 1,
          precioUnitario: existente.precioUnitario,
          nombreProducto: nombre,
        );
      } else {
        _detalles.add(DetallePedido(
          idPedido: 0,
          idProducto: idProducto,
          cantidad: 1,
          precioUnitario: precio,
          nombreProducto: nombre,
        ));
      }
    });
  }

  double get _total => _detalles.fold(0, (s, d) => s + d.subtotal);

  Future<void> _guardar() async {
    if (_clienteSeleccionado == null) {
      _showSnack('Selecciona un cliente');
      return;
    }
    if (_detalles.isEmpty) {
      _showSnack('Agrega productos');
      return;
    }
    setState(() { _loading = true; });
    try {
      final vendedor = ref.read(authControllerProvider).usuario;
      if (vendedor?.idUsuario == null) {
        _showSnack('No se detectó el vendedor. Cierra y vuelve a iniciar sesión.');
        setState(() { _loading = false; });
        return;
      }
      final pedido = await _pedidoService.crearPedido(
        idCliente: _clienteSeleccionado,
        idClienteContacto: null,
        idVendedor: vendedor?.idUsuario,
        detalles: _detalles,
        codigoDescuento: _codigoDescCtrl.text.trim().isEmpty ? null : _codigoDescCtrl.text.trim(),
        metodoPago: _metodoPago,
      );
      if (!mounted) return;
      _showSnack('Pedido creado #${pedido.idPedido}');
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productosState = ref.watch(productoControllerProvider);
    final productosFiltrados = productosState.productos.where((p) {
      final query = _productoFiltro.toLowerCase();
      final nombre = p.nombre.toLowerCase();
      final sku = p.sku.toLowerCase();
      final coincideTexto = query.isEmpty || nombre.contains(query) || sku.contains(query);
      final coincideStock = !_soloStock || p.stock > 0;
      return coincideTexto && coincideStock;
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Pedido')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _clienteSearchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Buscar cliente',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _clienteFiltro.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _clienteFiltro = '';
                                _clienteSearchCtrl.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _clienteFiltro = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: _clientesFiltrados.map((c) {
                    final nombre = c['nombre'] as String;
                    final esContacto = c['contacto'] == true;
                    final label = esContacto ? '$nombre (Contacto)' : nombre;
                    return DropdownMenuItem<int>(value: c['id'] as int?, child: Text(label));
                  }).toList(),
                  value: _clienteSeleccionado,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _clienteSeleccionado = v;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Método de pago'),
              initialValue: _metodoPago,
              items: const [
                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                DropdownMenuItem(value: 'nequi', child: Text('Nequi')),
              ],
              onChanged: (v) => setState(() => _metodoPago = v ?? 'efectivo'),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton.icon(
                onPressed: _creandoCliente ? null : _crearClienteRapido,
                icon: const Icon(Icons.person_add),
                label: const Text('Nuevo cliente'),
              ),
            ),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Productos', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            TextField(
                              controller: _productoSearchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Buscar producto o SKU',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _productoFiltro.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _productoFiltro = '';
                                            _productoSearchCtrl.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (v) => setState(() => _productoFiltro = v),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilterChip(
                                label: const Text('Solo con stock'),
                                selected: _soloStock,
                                onSelected: (v) => setState(() => _soloStock = v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: productosState.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : productosFiltrados.isEmpty
                                ? const Center(child: Text('Sin productos para estos filtros'))
                                : ListView.builder(
                                    itemCount: productosFiltrados.length,
                                    itemBuilder: (_, i) {
                                      final p = productosFiltrados[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: Text('\$${p.precio.toStringAsFixed(2)} | Stock: ${p.stock}'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          onPressed: p.stock > 0 ? () => _agregarProducto(p.idProducto!, p.precio, p.nombre) : null,
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: Colors.grey.shade300),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Detalle', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: _detalles.isEmpty
                            ? Center(child: Text('Sin productos'))
                            : ListView.separated(
                                itemCount: _detalles.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final d = _detalles[i];
                                  return ListTile(
                                    title: Text(d.nombreProducto ?? 'Producto'),
                                    subtitle: Text('${d.cantidad} x \$${d.precioUnitario.toStringAsFixed(2)}'),
                                    trailing: Text('\$${d.subtotal.toStringAsFixed(2)}'),
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal:12, vertical:4),
                        child: TextField(
                          controller: _codigoDescCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Código de descuento (opcional)',
                            prefixIcon: Icon(Icons.discount),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _guardar,
                            icon: const Icon(Icons.save),
                            label: _loading ? const Text('Guardando...') : const Text('Crear Pedido'),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
