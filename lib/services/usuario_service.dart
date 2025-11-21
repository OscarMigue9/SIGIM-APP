import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/rol.dart';
import 'supabase_service.dart';
import '../utils/password_utils.dart';

class UsuarioService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Obtener todos los usuarios
  Future<List<Usuario>> obtenerUsuarios() async {
    try {
      final response = await _client
          .from('usuario')
          .select('''
            *,
            rol:id_rol (
              id_rol,
              nombre_rol
            )
          ''')
          .order('nombre');

      return (response as List).map((json) {
        return Usuario.fromJson({
          ...json,
          'nombre_rol': json['rol']['nombre_rol'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  // Crear usuario
  Future<Usuario> crearUsuario(Usuario usuario) async {
    try {
      if (usuario.email == null || usuario.email!.isEmpty) {
        throw Exception('Email requerido');
      }

      // Crear en Supabase Auth (si es nuevo)
      if (usuario.contrasena != null && usuario.contrasena!.isNotEmpty) {
        try {
          await _client.auth.signUp(
            email: usuario.email!,
            password: usuario.contrasena!,
          );
        } catch (e) {
          // Si ya existe en Auth, continuamos para sincronizar la fila
          final msg = e.toString();
          if (!msg.contains('already registered')) rethrow;
        }
      }

      final userData = await _client.from('usuario').insert({
        'nombre': usuario.nombre,
        'apellido': usuario.apellido,
        'email': usuario.email,
        'contrasena': usuario.contrasena != null ? PasswordUtils.hash(usuario.contrasena!) : null,
        'id_rol': usuario.idRol,
      }).select('''
        *,
        rol:id_rol (
          id_rol,
          nombre_rol
        )
      ''').single();

      return Usuario.fromJson({
        ...userData,
        'nombre_rol': userData['rol']['nombre_rol'],
      });
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  // Actualizar usuario
  Future<Usuario> actualizarUsuario(Usuario usuario) async {
    try {
      if (usuario.idUsuario == null) {
        throw Exception('ID de usuario requerido para actualizar');
      }

      final userData = await _client.from('usuario').update({
        'nombre': usuario.nombre,
        'apellido': usuario.apellido,
        'email': usuario.email,
        'id_rol': usuario.idRol,
      }).eq('id_usuario', usuario.idUsuario!).select('''
        *,
        rol:id_rol (
          id_rol,
          nombre_rol
        )
      ''').single();

      return Usuario.fromJson({
        ...userData,
        'nombre_rol': userData['rol']['nombre_rol'],
      });
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  // Cambiar contraseña
  Future<bool> cambiarContrasena(int idUsuario, String nuevaContrasena) async {
    try {
      final hashed = PasswordUtils.hash(nuevaContrasena);
      await _client
          .from('usuario')
          .update({'contrasena': hashed})
          .eq('id_usuario', idUsuario);
      return true;
    } catch (e) {
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  // Eliminar usuario
  Future<bool> eliminarUsuario(int idUsuario) async {
    try {
      await _client
          .from('usuario')
          .delete()
          .eq('id_usuario', idUsuario);
      return true;
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // Obtener roles disponibles
  Future<List<Rol>> obtenerRoles() async {
    try {
      final response = await _client
          .from('rol')
          .select()
          .order('id_rol');

      return (response as List)
          .map((json) => Rol.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener roles: $e');
    }
  }

  // Buscar usuarios
  Future<List<Usuario>> buscarUsuarios(String query) async {
    try {
      final response = await _client
          .from('usuario')
          .select('''
            *,
            rol:id_rol (
              id_rol,
              nombre_rol
            )
          ''')
          .or('nombre.ilike.%$query%,apellido.ilike.%$query%')
          .order('nombre');

      return (response as List).map((json) {
        return Usuario.fromJson({
          ...json,
          'nombre_rol': json['rol']['nombre_rol'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios: $e');
    }
  }

  // Obtener estadísticas de usuarios
  Future<Map<String, int>> obtenerEstadisticasUsuarios() async {
    try {
      final usuarios = await obtenerUsuarios();
      
      int admins = 0, vendedores = 0, clientes = 0;
      
      for (final usuario in usuarios) {
        switch (usuario.idRol) {
          case 1: admins++; break;
          case 2: vendedores++; break;
          case 3: clientes++; break;
        }
      }

      return {
        'total': usuarios.length,
        'administradores': admins,
        'vendedores': vendedores,
        'clientes': clientes,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Obtener solo clientes (rol == 3)
  Future<List<Usuario>> obtenerClientes() async {
    try {
      final response = await _client
          .from('usuario')
          .select('''
            id_usuario, nombre, apellido, id_rol
          ''')
          .eq('id_rol', 3)
          .order('nombre');

      return (response as List).map((json) {
        return Usuario.fromJson({
          ...json,
          // nombre_rol opcional: lo resolvemos estático para evitar join
          'nombre_rol': 'Cliente',
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }
}
