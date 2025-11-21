import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/rol.dart';
import 'supabase_service.dart';
import '../utils/password_utils.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.instance.client;

  static Usuario? _currentUser;

  Future<Usuario?> _fetchUsuarioPorEmail(String email) async {
    final row = await _client
        .from('usuario')
        .select('''
          *,
          rol:id_rol (
            id_rol,
            nombre_rol
          )
        ''')
        .eq('email', email)
        .maybeSingle();
    if (row == null) return null;
    return Usuario.fromJson({...row, 'nombre_rol': row['rol']['nombre_rol']});
  }

  Future<Usuario?> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final authUser = res.user;
      if (authUser == null) {
        final legacy = await _legacyLogin(email, password);
        if (legacy != null) {
          _currentUser = legacy;
          return legacy;
        }
        return null;
      }
      final usuario = await _fetchUsuarioPorEmail(authUser.email ?? email);
      _currentUser = usuario;
      return usuario;
    } on AuthException catch (authError) {
      final legacy = await _legacyLogin(email, password);
      if (legacy != null) {
        _currentUser = legacy;
        return legacy;
      }
      throw Exception(authError.message);
    } catch (e) {
      throw Exception('Error autenticando: $e');
    }
  }

  Future<Usuario?> _legacyLogin(String email, String password) async {
    final usuario = await _fetchUsuarioPorEmail(email);
    if (usuario == null) return null;

    final stored = usuario.contrasena;
    if (stored == null || !PasswordUtils.verify(password, stored)) {
      return null;
    }

    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      final alreadyRegistered = e.message.toLowerCase().contains('registered');
      if (!alreadyRegistered) rethrow;
    }

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (_) {
      // Ignorar: si la sesión ya está activa, esta llamada puede fallar.
    }

    return usuario;
  }

  Future<Usuario?> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    int? idRol,
  }) async {
    try {
      final policyError = PasswordUtils.validate(password);
      if (policyError != null) throw Exception(policyError);

      // Crear cuenta en Supabase Auth
      await _client.auth.signUp(email: email, password: password);

      // Determinar rol (primero admin, resto cliente por defecto)
      final first = await _client.from('usuario').select('id_usuario').limit(1);
      final finalRol =
          idRol ??
          (first.isEmpty ? RolConstants.administrador : RolConstants.cliente);
      final hashed = PasswordUtils.hash(password);

      final existing = await _client
          .from('usuario')
          .select('id_usuario, id_rol')
          .eq('email', email)
          .maybeSingle();

      final payload = {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'contrasena': hashed,
        'id_rol': finalRol,
      };

      final row = existing != null
          ? await _client
                .from('usuario')
                .update(payload)
                .eq('id_usuario', existing['id_usuario'])
                .select('''
                *,
                rol:id_rol (
                  id_rol,
                  nombre_rol
                )
              ''')
                .single()
          : await _client.from('usuario').insert(payload).select('''
                *,
                rol:id_rol (
                  id_rol,
                  nombre_rol
                )
              ''').single();

      final usuario = Usuario.fromJson({
        ...row,
        'nombre_rol': row['rol']['nombre_rol'],
      });
      _currentUser = usuario;
      return usuario;
    } catch (e) {
      throw Exception('Error registro: $e');
    }
  }

  Future<Usuario?> getCurrentUserData() async {
    if (_currentUser != null) return _currentUser;
    final authUser = _client.auth.currentUser;
    if (authUser?.email == null) return null;
    _currentUser = await _fetchUsuarioPorEmail(authUser!.email!);
    return _currentUser;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _client.auth.signOut();
  }

  // Método para establecer usuario actual después del login
  void setCurrentUser(Usuario usuario) {
    _currentUser = usuario;
  }

  Future<bool> changePassword(int idUsuario, String newPassword) async {
    try {
      final policyError = PasswordUtils.validate(newPassword);
      if (policyError != null) throw Exception(policyError);

      await _client.auth.updateUser(UserAttributes(password: newPassword));

      // Mantener la columna contrasena sincronizada (hash local)
      final hashed = PasswordUtils.hash(newPassword);
      await _client
          .from('usuario')
          .update({'contrasena': hashed})
          .eq('id_usuario', idUsuario);
      return true;
    } catch (e) {
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  // Método para cambiar rol de usuario
  Future<bool> changeUserRole(int idUsuario, int newRol) async {
    try {
      await _client
          .from('usuario')
          .update({'id_rol': newRol})
          .eq('id_usuario', idUsuario);
      return true;
    } catch (e) {
      throw Exception('Error al cambiar rol: $e');
    }
  }

  Future<List<Usuario>> getAllUsers() async {
    if (_currentUser == null || !_currentUser!.esAdministrador) {
      throw Exception('Acceso denegado');
    }
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
          .order('id_usuario');

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
}
