import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/cliente_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/direccion_pago_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dirPagoSvc = DireccionPagoService();

  // Entrega
  String _tipoEntrega = 'envio'; // 'envio' | 'retiro'
  final _calleCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _provinciaCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();
  final _referenciasCtrl = TextEditingController();

  // Pago
  String _metodoPago = 'tarjeta'; // 'tarjeta' | 'transferencia' | 'nequi' | 'efectivo'
  List<Map<String, dynamic>> _direcciones = [];
  List<Map<String, dynamic>> _metodos = [];
  int? _direccionSeleccionada; // id_direccion
  int? _metodoSeleccionado; // id_metodo
  final _tarjetaNumeroCtrl = TextEditingController();
  final _tarjetaNombreCtrl = TextEditingController();
  final _tarjetaFechaCtrl = TextEditingController();
  final _tarjetaCvvCtrl = TextEditingController();
  final _transferRefCtrl = TextEditingController();

  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromSaved());
  }

  Future<void> _prefillFromSaved() async {
    final usuario = ref.read(authControllerProvider).usuario;
    if (usuario == null) return;
    try {
      final dirs = await _dirPagoSvc.obtenerDireccionesUsuario(usuario.idUsuario!);
      final mets = await _dirPagoSvc.obtenerMetodosPagoUsuario(usuario.idUsuario!);
      setState(() {
        _direcciones = dirs;
        _metodos = mets;
      });
      if (dirs.isNotEmpty) {
        final d = dirs.first; // ya ordenado por default primero
        _direccionSeleccionada = d['id_direccion'] as int?;
        _tipoEntrega = 'envio';
        _calleCtrl.text = (d['linea1'] ?? '').toString();
        _numeroCtrl.text = (d['linea2'] ?? '').toString();
        _ciudadCtrl.text = (d['ciudad'] ?? '').toString();
        _provinciaCtrl.text = (d['provincia'] ?? '').toString();
        _cpCtrl.text = (d['cp'] ?? '').toString();
        _referenciasCtrl.text = (d['referencias'] ?? '').toString();
      }
      if (mets.isNotEmpty) {
        final m = mets.first;
        _metodoSeleccionado = m['id_metodo'] as int?;
        final tipo = (m['tipo'] ?? 'tarjeta').toString();
        final datos = (m['datos'] ?? {}) as Map<String, dynamic>;
        _metodoPago = tipo;
        if (tipo == 'transferencia' || tipo == 'nequi') {
          _transferRefCtrl.text = (datos['referencia'] ?? '').toString();
        } else if (tipo == 'efectivo') {
          _tipoEntrega = 'retiro';
        }
        setState(() {});
      }
    } catch (_) {
      // Silenciar prefill; no es crítico si falla
    }
  }

  @override
  void dispose() {
    _calleCtrl.dispose();
    _numeroCtrl.dispose();
    _ciudadCtrl.dispose();
    _provinciaCtrl.dispose();
    _cpCtrl.dispose();
    _referenciasCtrl.dispose();
    _tarjetaNumeroCtrl.dispose();
    _tarjetaNombreCtrl.dispose();
    _tarjetaFechaCtrl.dispose();
    _tarjetaCvvCtrl.dispose();
    _transferRefCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final carrito = ref.read(carritoControllerProvider);
    final usuario = ref.read(authControllerProvider).usuario;
    if (usuario == null) {
      _showSnack('Debes iniciar sesión');
      return;
    }
    if (carrito.items.isEmpty) {
      _showSnack('Tu carrito está vacío');
      return;
    }

    if (_metodoPago == 'efectivo' && _tipoEntrega != 'retiro') {
      _showSnack('El método Efectivo solo está disponible para Retiro en tienda');
      return;
    }

    if (_tipoEntrega == 'envio') {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _processing = true);
    try {
      final direccion = _tipoEntrega == 'envio'
          ? '${_calleCtrl.text.trim()} ${_numeroCtrl.text.trim()}, ${_ciudadCtrl.text.trim()}, ${_provinciaCtrl.text.trim()}, CP ${_cpCtrl.text.trim()}${_referenciasCtrl.text.trim().isEmpty ? '' : ' (${_referenciasCtrl.text.trim()})'}'
          : null;

      String? pagoReferencia;
      if (_metodoPago == 'tarjeta') {
        // Guardar sólo referencia básica, no datos sensibles
        final num = _tarjetaNumeroCtrl.text.replaceAll(' ', '');
        final ult4 = num.length >= 4 ? num.substring(num.length - 4) : num;
        pagoReferencia = 'Tarjeta **** $ult4';
      } else if (_metodoPago == 'transferencia') {
        pagoReferencia = 'Transferencia ${_transferRefCtrl.text.trim()}';
      } else if (_metodoPago == 'nequi') {
        pagoReferencia = 'Nequi ${_transferRefCtrl.text.trim()}';
      } else {
        pagoReferencia = 'Efectivo';
      }

      // Ejecutar pedido avanzado desde el servicio del carrito
      final exito = await ref.read(carritoControllerProvider.notifier).procesarPedidoAvanzado(
            idCliente: usuario.idUsuario!,
            tipoEntrega: _tipoEntrega,
            direccionEnvio: direccion,
            metodoPago: _metodoPago,
            pagoReferencia: pagoReferencia,
          );

      if (!mounted) return;
      if (exito) {
        _showSnack('¡Pedido creado con éxito!');
        Navigator.pop(context, true);
      } else {
        _showSnack('No se pudo crear el pedido');
      }
    } catch (e) {
      _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo de entrega', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_direcciones.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _direccionSeleccionada,
                  decoration: const InputDecoration(labelText: 'Seleccionar dirección guardada'),
                  items: _direcciones.map((d) => DropdownMenuItem<int>(
                    value: d['id_direccion'] as int?,
                    child: Text('${d['linea1']}${d['ciudad'] != null ? ' - ${d['ciudad']}' : ''}'),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _direccionSeleccionada = v;
                      final d = _direcciones.firstWhere((e) => e['id_direccion'] == v);
                      _calleCtrl.text = (d['linea1'] ?? '').toString();
                      _numeroCtrl.text = (d['linea2'] ?? '').toString();
                      _ciudadCtrl.text = (d['ciudad'] ?? '').toString();
                      _provinciaCtrl.text = (d['provincia'] ?? '').toString();
                      _cpCtrl.text = (d['cp'] ?? '').toString();
                      _referenciasCtrl.text = (d['referencias'] ?? '').toString();
                      _tipoEntrega = 'envio';
                    });
                  },
                ),
              if (_direcciones.isNotEmpty) const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _tipoEntrega,
                onChanged: (v) => setState(() => _tipoEntrega = v ?? 'envio'),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'envio',
                        title: const Text('Envío a domicilio'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'retiro',
                        title: const Text('Retiro en tienda'),
                      ),
                    ),
                  ],
                ),
              ),

              if (_tipoEntrega == 'envio') ...[
                const SizedBox(height: 12),
                Text('Dirección de envío', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _calleCtrl,
                  decoration: const InputDecoration(labelText: 'Calle'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numeroCtrl,
                      decoration: const InputDecoration(labelText: 'Número'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cpCtrl,
                      decoration: const InputDecoration(labelText: 'Código Postal'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ]),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ciudadCtrl,
                      decoration: const InputDecoration(labelText: 'Ciudad'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _provinciaCtrl,
                      decoration: const InputDecoration(labelText: 'Provincia'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ]),
                TextFormField(
                  controller: _referenciasCtrl,
                  decoration: const InputDecoration(labelText: 'Referencias (opcional)'),
                ),
              ],

              const SizedBox(height: 16),
              Text('Método de pago', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_metodos.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _metodoSeleccionado,
                  decoration: const InputDecoration(labelText: 'Seleccionar método guardado'),
                  items: _metodos.map((m) => DropdownMenuItem<int>(
                    value: m['id_metodo'] as int?,
                    child: Text(_descripcionMetodo(m)),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _metodoSeleccionado = v;
                      final m = _metodos.firstWhere((e) => e['id_metodo'] == v);
                      final tipo = (m['tipo'] ?? 'tarjeta').toString();
                      _metodoPago = tipo;
                      final datos = (m['datos'] ?? {}) as Map<String, dynamic>;
                      if (tipo == 'transferencia' || tipo == 'nequi') {
                        _transferRefCtrl.text = (datos['referencia'] ?? '').toString();
                      } else {
                        _transferRefCtrl.clear();
                      }
                      if (tipo == 'efectivo') _tipoEntrega = 'retiro';
                    });
                  },
                ),
              if (_metodos.isNotEmpty) const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _metodoPago,
                items: const [
                  DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                  DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'nequi', child: Text('Nequi')),
                  DropdownMenuItem(value: 'efectivo', child: Text('Efectivo (solo retiro)')),
                ],
                onChanged: (v) => setState(() => _metodoPago = v ?? 'tarjeta'),
                validator: (v) {
                  if (v == 'efectivo' && _tipoEntrega != 'retiro') {
                    return 'Efectivo solo disponible para retiro en tienda';
                  }
                  return null;
                },
              ),

              if (_metodoPago == 'tarjeta') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tarjetaNumeroCtrl,
                  decoration: const InputDecoration(labelText: 'Número de tarjeta'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.replaceAll(' ', '').length < 12) ? 'Número inválido' : null,
                ),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tarjetaNombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre en la tarjeta'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ]),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tarjetaFechaCtrl,
                      decoration: const InputDecoration(labelText: 'Vencimiento (MM/AA)'),
                      validator: (v) => (v == null || !RegExp(r"^(0[1-9]|1[0-2])\/[0-9]{2}").hasMatch(v)) ? 'Formato inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tarjetaCvvCtrl,
                      decoration: const InputDecoration(labelText: 'CVV'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().length < 3) ? 'CVV inválido' : null,
                    ),
                  ),
                ]),
              ] else if (_metodoPago == 'transferencia') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _transferRefCtrl,
                  decoration: const InputDecoration(labelText: 'Referencia de transferencia'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ] else if (_metodoPago == 'nequi') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _transferRefCtrl,
                  decoration: const InputDecoration(labelText: 'Número Nequi / Referencia'),
                  validator: (v) => (v == null || v.trim().length < 8) ? 'Número/referencia inválido' : null,
                ),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: \$${carrito.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _processing ? null : _confirmar,
                    icon: const Icon(Icons.check_circle),
                    label: Text(_processing ? 'Procesando...' : 'Confirmar pedido'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _descripcionMetodo(Map<String, dynamic> m) {
    final tipo = (m['tipo'] ?? '').toString();
    final alias = (m['alias'] ?? '').toString();
    final datos = (m['datos'] ?? {}) as Map<String, dynamic>;
    String base;
    if (tipo == 'tarjeta') {
      base = 'Tarjeta ****${datos['last4'] ?? '----'}';
    } else if (tipo == 'transferencia') {
      base = 'Transferencia ${datos['referencia'] ?? ''}';
    } else if (tipo == 'nequi') {
      base = 'Nequi ${datos['referencia'] ?? ''}';
    } else {
      base = 'Efectivo';
    }
    return [alias, base].where((s) => s.trim().isNotEmpty).join(' • ');
  }
}
