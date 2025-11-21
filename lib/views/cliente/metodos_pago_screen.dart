import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../services/direccion_pago_service.dart';

class MetodosPagoScreen extends ConsumerStatefulWidget {
  const MetodosPagoScreen({super.key});

  @override
  ConsumerState<MetodosPagoScreen> createState() => _MetodosPagoScreenState();
}

class _MetodosPagoScreenState extends ConsumerState<MetodosPagoScreen> {
  final _svc = DireccionPagoService();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final user = ref.read(authControllerProvider).usuario;
    if (user == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _svc.obtenerMetodosPagoUsuario(user.idUsuario!);
      setState(() { _items = res; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _formNuevoMetodo() async {
    final user = ref.read(authControllerProvider).usuario;
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final formKey = GlobalKey<FormState>();
    String tipo = 'tarjeta';
    final alias = TextEditingController();
    final last4 = TextEditingController();
    final nombreTarj = TextEditingController();
    final venc = TextEditingController();
    final referencia = TextEditingController();
    bool esDefault = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Nuevo método de pago'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    items: const [
                      DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta (solo últimos 4)')),
                      DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                      DropdownMenuItem(value: 'nequi', child: Text('Nequi')),
                      DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                    ],
                    onChanged: (v) => setS(() => tipo = v ?? 'tarjeta'),
                  ),
                  TextFormField(
                    controller: alias,
                    decoration: const InputDecoration(labelText: 'Alias (opcional)'),
                  ),
                  if (tipo == 'tarjeta') ...[
                    TextFormField(
                      controller: last4,
                      decoration: const InputDecoration(labelText: 'Últimos 4 dígitos'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().length != 4) ? 'Ingresa 4 dígitos' : null,
                    ),
                    TextFormField(
                      controller: nombreTarj,
                      decoration: const InputDecoration(labelText: 'Nombre en la tarjeta'),
                    ),
                    TextFormField(
                      controller: venc,
                      decoration: const InputDecoration(labelText: 'Vencimiento (MM/AA)'),
                    ),
                  ] else if (tipo == 'transferencia') ...[
                    TextFormField(
                      controller: referencia,
                      decoration: const InputDecoration(labelText: 'Referencia bancaria'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ] else if (tipo == 'nequi') ...[
                    TextFormField(
                      controller: referencia,
                      decoration: const InputDecoration(labelText: 'Número Nequi'),
                      validator: (v) => (v == null || v.trim().length < 8) ? 'Número inválido' : null,
                    ),
                  ],
                  CheckboxListTile(
                    value: esDefault,
                    onChanged: (v) => setS(() => esDefault = v ?? false),
                    title: const Text('Marcar como predeterminado'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                Map<String, dynamic>? datos;
                if (tipo == 'tarjeta') {
                  datos = {
                    'last4': last4.text.trim(),
                    'nombre': nombreTarj.text.trim(),
                    'venc': venc.text.trim(),
                  };
                } else if (tipo == 'transferencia' || tipo == 'nequi') {
                  datos = {'referencia': referencia.text.trim()};
                }
                await _svc.crearMetodoPago(
                  idUsuario: user.idUsuario!,
                  tipo: tipo,
                  alias: alias.text.trim().isEmpty ? null : alias.text.trim(),
                  datos: datos,
                  esDefault: esDefault,
                );
                if (!mounted) return;
                navigator.pop(true);
              } catch (e) {
                if (!mounted) return;
                navigator.pop(false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error: ${e.toString().replaceAll('Exception: ', '')}',
                    ),
                  ),
                );
              }
            }, child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (ok == true) _cargar();
  }

  Future<void> _eliminar(Map<String, dynamic> item) async {
    final user = ref.read(authControllerProvider).usuario;
    if (user == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar método'),
        content: const Text('¿Deseas eliminar este método de pago?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await _svc.eliminarMetodoPago(item['id_metodo'] as int, user.idUsuario!);
      _cargar();
    }
  }

  String _resumenMetodo(Map<String, dynamic> m) {
    final tipo = (m['tipo'] ?? '').toString();
    final alias = (m['alias'] ?? '').toString();
    final datos = (m['datos'] ?? {}) as Map<String, dynamic>;
    String detalle = '';
    if (tipo == 'tarjeta') {
      detalle = '**** ${datos['last4'] ?? '----'}';
    } else if (tipo == 'transferencia') {
      detalle = 'Ref ${datos['referencia'] ?? ''}';
    } else if (tipo == 'nequi') {
      detalle = 'Nequi ${datos['referencia'] ?? ''}';
    } else if (tipo == 'efectivo') {
      detalle = 'Efectivo (retiro)';
    }
  return [alias, detalle].where((s) => s.toString().trim().isNotEmpty).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis métodos de pago')),
      floatingActionButton: FloatingActionButton(
        onPressed: _formNuevoMetodo,
        child: const Icon(Icons.add_card),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _items.isEmpty
                  ? const Center(child: Text('No tienes métodos de pago. Usa + para agregar uno.'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (_, i) {
                        final m = _items[i];
                        return ListTile(
                          leading: Icon(m['es_default'] == true ? Icons.star : Icons.credit_card, color: m['es_default'] == true ? Colors.amber : null),
                          title: Text((m['tipo'] as String).toUpperCase()),
                          subtitle: Text(_resumenMetodo(m)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'default') {
                                await _svc.actualizarMetodoPago(
                                  idMetodo: m['id_metodo'] as int,
                                  idUsuario: ref.read(authControllerProvider).usuario!.idUsuario!,
                                  esDefault: true,
                                );
                                _cargar();
                              } else if (v == 'eliminar') {
                                _eliminar(m);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'default', child: Text('Marcar como predeterminado')),
                              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
