import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/usuario_controller.dart';
import '../../models/usuario.dart';

class GestionUsuariosScreen extends ConsumerStatefulWidget {
  final bool autoOpenCreate;
  const GestionUsuariosScreen({super.key, this.autoOpenCreate = false});

  @override
  ConsumerState<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends ConsumerState<GestionUsuariosScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _rolFiltro;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usuarioControllerProvider.notifier).cargarUsuarios();
      if (widget.autoOpenCreate) {
        // Abrir diálogo de creación automáticamente después de cargar
        _mostrarDialogoUsuario(context);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuarioState = ref.watch(usuarioControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(usuarioControllerProvider.notifier).cargarUsuarios();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y estadísticas
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar usuarios...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(usuarioControllerProvider.notifier).buscarUsuarios('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(usuarioControllerProvider.notifier).buscarUsuarios(value);
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _rolFiltro == null,
                        onSelected: (_) => setState(() => _rolFiltro = null),
                      ),
                      ChoiceChip(
                        label: const Text('Admins'),
                        selected: _rolFiltro == 1,
                        onSelected: (_) => setState(() => _rolFiltro = 1),
                      ),
                      ChoiceChip(
                        label: const Text('Vendedores'),
                        selected: _rolFiltro == 2,
                        onSelected: (_) => setState(() => _rolFiltro = 2),
                      ),
                      ChoiceChip(
                        label: const Text('Clientes'),
                        selected: _rolFiltro == 3,
                        onSelected: (_) => setState(() => _rolFiltro = 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Estadísticas
                if (usuarioState.estadisticas != null)
                  _buildEstadisticas(usuarioState.estadisticas!),
              ],
            ),
          ),
          
          // Lista de usuarios
          Expanded(
            child: _buildUsuariosList(usuarioState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoUsuario(context),
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildEstadisticas(Map<String, int> estadisticas) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildEstadisticaItem(
              'Total',
              estadisticas['total'].toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildEstadisticaItem(
              'Admins',
              estadisticas['administradores'].toString(),
              Icons.admin_panel_settings,
              Colors.red,
            ),
            _buildEstadisticaItem(
              'Vendedores',
              estadisticas['vendedores'].toString(),
              Icons.storefront,
              Colors.green,
            ),
            _buildEstadisticaItem(
              'Clientes',
              estadisticas['clientes'].toString(),
              Icons.shopping_cart,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaItem(String titulo, String valor, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<Usuario> _filtrarUsuarios(UsuarioState state) {
    if (_rolFiltro == null) return state.usuarios;
    return state.usuarios.where((u) => u.idRol == _rolFiltro).toList();
  }

  Widget _buildUsuariosList(UsuarioState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(usuarioControllerProvider.notifier).cargarUsuarios(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final usuarios = _filtrarUsuarios(state);

    if (usuarios.isEmpty) {
      final tieneFiltro = _rolFiltro != null || _searchController.text.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(tieneFiltro ? 'Sin resultados para estos filtros' : 'No hay usuarios registrados'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: usuarios.length,
      itemBuilder: (context, index) {
        final usuario = usuarios[index];
        return _buildUsuarioCard(usuario);
      },
    );
  }

  Widget _buildUsuarioCard(Usuario usuario) {
    Color rolColor;
    IconData rolIcon;
    
    switch (usuario.idRol) {
      case 1:
        rolColor = Colors.red;
        rolIcon = Icons.admin_panel_settings;
        break;
      case 2:
        rolColor = Colors.green;
        rolIcon = Icons.storefront;
        break;
      default:
        rolColor = Colors.orange;
        rolIcon = Icons.shopping_cart;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rolColor.withValues(alpha: 0.1),
          child: Icon(rolIcon, color: rolColor),
        ),
        title: Text('${usuario.nombre} ${usuario.apellido}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario.nombreRol ?? 'Sin rol'),
            Text(
              'ID: ${usuario.idUsuario}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, usuario),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'contrasena',
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Cambiar Contraseña'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _handleMenuAction(String action, Usuario usuario) {
    switch (action) {
      case 'editar':
        _mostrarDialogoUsuario(context, usuario: usuario);
        break;
      case 'contrasena':
        _mostrarDialogoCambiarContrasena(context, usuario);
        break;
      case 'eliminar':
        _mostrarDialogoEliminar(context, usuario);
        break;
    }
  }

  void _mostrarDialogoUsuario(BuildContext context, {Usuario? usuario}) {
    showDialog(
      context: context,
      builder: (context) => _UsuarioDialog(usuario: usuario),
    );
  }

  void _mostrarDialogoCambiarContrasena(BuildContext context, Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => _CambiarContrasenaDialog(usuario: usuario),
    );
  }

  void _mostrarDialogoEliminar(BuildContext context, Usuario usuario) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro que quieres eliminar a ${usuario.nombre} ${usuario.apellido}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              navigator.pop();
              final success = await ref.read(usuarioControllerProvider.notifier)
                  .eliminarUsuario(usuario.idUsuario!);
              
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success 
                      ? 'Usuario eliminado exitosamente'
                      : 'Error al eliminar usuario'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _UsuarioDialog extends ConsumerStatefulWidget {
  final Usuario? usuario;
  
  const _UsuarioDialog({this.usuario});

  @override
  ConsumerState<_UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends ConsumerState<_UsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();
  int _selectedRolId = 3; // Cliente por defecto

  @override
  void initState() {
    super.initState();
    if (widget.usuario != null) {
      _nombreController.text = widget.usuario!.nombre;
      _apellidoController.text = widget.usuario!.apellido;
      _emailController.text = widget.usuario!.email ?? '';
      _selectedRolId = widget.usuario!.idRol;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuarioState = ref.watch(usuarioControllerProvider);
    final isEditing = widget.usuario != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Usuario' : 'Crear Usuario'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apellidoController,
              decoration: const InputDecoration(
                labelText: 'Apellido',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El apellido es requerido';
                }
                return null;
              },
            ),
            if (!isEditing) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return 'El correo es requerido';
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contrasenaController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es requerida';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedRolId,
              decoration: const InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
              items: usuarioState.roles.map((rol) {
                return DropdownMenuItem(
                  value: rol.idRol,
                  child: Text(rol.nombreRol),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRolId = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: usuarioState.isLoading ? null : _guardarUsuario,
          child: usuarioState.isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = Usuario(
      idUsuario: widget.usuario?.idUsuario,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: widget.usuario != null
          ? (widget.usuario!.email ?? '')
          : _emailController.text.trim().toLowerCase(),
      contrasena: widget.usuario != null ? widget.usuario!.contrasena : _contrasenaController.text,
      idRol: _selectedRolId,
    );

    final success = widget.usuario != null
        ? await ref.read(usuarioControllerProvider.notifier).actualizarUsuario(usuario)
        : await ref.read(usuarioControllerProvider.notifier).crearUsuario(usuario);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.usuario != null 
                ? 'Usuario actualizado exitosamente'
                : 'Usuario creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(usuarioControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Error al guardar usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CambiarContrasenaDialog extends ConsumerStatefulWidget {
  final Usuario usuario;
  
  const _CambiarContrasenaDialog({required this.usuario});

  @override
  ConsumerState<_CambiarContrasenaDialog> createState() => _CambiarContrasenaDialogState();
}

class _CambiarContrasenaDialogState extends ConsumerState<_CambiarContrasenaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  @override
  void dispose() {
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar Contraseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cambiar contraseña para: ${widget.usuario.nombre} ${widget.usuario.apellido}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nuevaContrasenaController,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es requerida';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmarContrasenaController,
              decoration: const InputDecoration(
                labelText: 'Confirmar Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value != _nuevaContrasenaController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _cambiarContrasena,
          child: const Text('Cambiar'),
        ),
      ],
    );
  }

  Future<void> _cambiarContrasena() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(usuarioControllerProvider.notifier)
        .cambiarContrasena(widget.usuario.idUsuario!, _nuevaContrasenaController.text);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Contraseña cambiada exitosamente'
              : 'Error al cambiar contraseña'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
