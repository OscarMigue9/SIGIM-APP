import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../services/direccion_pago_service.dart';

class DireccionesScreen extends ConsumerStatefulWidget {
  const DireccionesScreen({super.key});

  @override
  ConsumerState<DireccionesScreen> createState() => _DireccionesScreenState();
}

class _DireccionesScreenState extends ConsumerState<DireccionesScreen> {
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
      final res = await _svc.obtenerDireccionesUsuario(user.idUsuario!);
      setState(() { _items = res; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _formNuevaOEditar({Map<String, dynamic>? existente}) async {
    final user = ref.read(authControllerProvider).usuario;
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final formKey = GlobalKey<FormState>();
    final linea1 = TextEditingController(text: existente?['linea1']);
    final linea2 = TextEditingController(text: existente?['linea2']);
    final ciudad = TextEditingController(text: existente?['ciudad']);
    final provincia = TextEditingController(text: existente?['provincia']);
    final cp = TextEditingController(text: existente?['cp']);
    final refCtrl = TextEditingController(text: existente?['referencias']);
    bool esDefault = (existente?['es_default'] ?? false) as bool;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existente == null ? 'Nueva dirección' : 'Editar dirección'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: linea1,
                  decoration: const InputDecoration(labelText: 'Dirección (línea 1)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: linea2,
                  decoration: const InputDecoration(labelText: 'Dirección (línea 2, opcional)'),
                ),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: ciudad,
                    decoration: const InputDecoration(labelText: 'Ciudad'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: provincia,
                    decoration: const InputDecoration(labelText: 'Provincia'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  )),
                ]),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: cp,
                    decoration: const InputDecoration(labelText: 'Código Postal'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  )),
                ]),
                TextFormField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: 'Referencias (opcional)'),
                ),
                CheckboxListTile(
                  value: esDefault,
                  onChanged: (v) => setState(() { esDefault = v ?? false; }),
                  title: const Text('Marcar como predeterminada'),
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
              if (existente == null) {
                await _svc.crearDireccion(
                  idUsuario: user.idUsuario!,
                  linea1: linea1.text.trim(),
                  linea2: linea2.text.trim().isEmpty ? null : linea2.text.trim(),
                  ciudad: ciudad.text.trim(),
                  provincia: provincia.text.trim(),
                  cp: cp.text.trim(),
                  referencias: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
                  esDefault: esDefault,
                );
              } else {
                await _svc.actualizarDireccion(
                  idDireccion: existente['id_direccion'] as int,
                  idUsuario: user.idUsuario!,
                  linea1: linea1.text.trim(),
                  linea2: linea2.text.trim().isEmpty ? null : linea2.text.trim(),
                  ciudad: ciudad.text.trim(),
                  provincia: provincia.text.trim(),
                  cp: cp.text.trim(),
                  referencias: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
                  esDefault: esDefault,
                );
              }
              if (!mounted) return;
              navigator.pop(true);
            } catch (e) {
              if (!mounted) return;
              navigator.pop(false);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                ),
              );
            }
          }, child: const Text('Guardar')),
        ],
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
        title: const Text('Eliminar dirección'),
        content: const Text('¿Deseas eliminar esta dirección?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await _svc.eliminarDireccion(item['id_direccion'] as int, user.idUsuario!);
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis direcciones')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _formNuevaOEditar(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _items.isEmpty
                  ? const Center(child: Text('No tienes direcciones. Usa + para agregar una.'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (_, i) {
                        final d = _items[i];
                        return ListTile(
                          leading: Icon(d['es_default'] == true ? Icons.star : Icons.location_on_outlined, color: d['es_default'] == true ? Colors.amber : null),
                          title: Text(d['linea1'] ?? ''),
                          subtitle: Text('${d['ciudad'] ?? ''}, ${d['provincia'] ?? ''} • CP ${d['cp'] ?? ''}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'editar') {
                                _formNuevaOEditar(existente: d);
                              } else if (v == 'eliminar') {
                                _eliminar(d);
                              } else if (v == 'default') {
                                _svc
                                    .actualizarDireccion(
                                      idDireccion: d['id_direccion'] as int,
                                      idUsuario: ref.read(authControllerProvider).usuario!.idUsuario!,
                                      linea1: d['linea1'] ?? '',
                                      linea2: d['linea2'],
                                      ciudad: d['ciudad'] ?? '',
                                      provincia: d['provincia'] ?? '',
                                      cp: d['cp'] ?? '',
                                      referencias: d['referencias'],
                                      esDefault: true,
                                    )
                                    .then((_) => _cargar());
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'editar', child: Text('Editar')),
                              const PopupMenuItem(value: 'default', child: Text('Marcar como predeterminada')),
                              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
