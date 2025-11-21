import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/usuario_controller.dart';
import '../../models/usuario.dart';
import '../../utils/password_utils.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authControllerProvider).usuario;
    if (u != null) {
      _nombreCtrl.text = u.nombre;
      _apellidoCtrl.text = u.apellido;
      _emailCtrl.text = u.email ?? '';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final auth = ref.read(authControllerProvider);
      final usuario = auth.usuario;
      if (usuario == null) throw Exception('No autenticado');
      final actualizado = Usuario(
        idUsuario: usuario.idUsuario,
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        contrasena: usuario.contrasena,
        idRol: usuario.idRol,
        nombreRol: usuario.nombreRol,
      );
      final ok = await ref.read(usuarioControllerProvider.notifier).actualizarUsuario(actualizado);
      if (!ok) throw Exception('Error actualizando perfil');
      if (_passwordCtrl.text.isNotEmpty) {
        final err = PasswordUtils.validate(_passwordCtrl.text);
        if (err != null) throw Exception(err);
        final changed = await ref.read(authControllerProvider.notifier).changePassword(_passwordCtrl.text);
        if (!changed) throw Exception('Error cambiando contraseña');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      Navigator.pop(context);
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final usuario = auth.usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: usuario == null
          ? const Center(child: Text('No autenticado'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apellidoCtrl,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Nueva contraseña (opcional)'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _guardar,
                            child: _saving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Guardar Cambios'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}