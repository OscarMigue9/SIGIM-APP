import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../utils/password_utils.dart';

// Estado de autenticación
class AuthState {
  final Usuario? usuario;
  final bool isLoading;
  final String? error;

  AuthState({this.usuario, this.isLoading = false, this.error});

  AuthState copyWith({Usuario? usuario, bool? isLoading, String? error}) {
    return AuthState(
      usuario: usuario ?? this.usuario,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => usuario != null;
  bool get esAdministrador => usuario?.esAdministrador ?? false;
  bool get esVendedor => usuario?.esVendedor ?? false;
  bool get esCliente => usuario?.esCliente ?? false;
}

// Controller de autenticación
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final usuario = await _authService.getCurrentUserData().timeout(
        const Duration(seconds: 6),
        onTimeout: () => null,
      );
      state = state.copyWith(usuario: usuario, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usuario = await _authService.login(email, password);
      if (usuario != null) {
        // Establecer usuario actual en el servicio
        _authService.setCurrentUser(usuario);

        state = state.copyWith(usuario: usuario, isLoading: false, error: null);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Credenciales inválidas');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    int? idRol,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usuario = await _authService.register(
        nombre: nombre,
        apellido: apellido,
        email: email,
        password: password,
        idRol: idRol ?? 3, // Cliente por defecto
      );
      if (usuario != null) {
        // Establecer usuario actual en el servicio
        _authService.setCurrentUser(usuario);

        state = state.copyWith(usuario: usuario, isLoading: false, error: null);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Error al registrar usuario',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      // Ignorar errores del logout
      debugPrint('Error en logout: $e');
    } finally {
      // Siempre limpiar el estado
      state = AuthState();
    }
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      final policyError = PasswordUtils.validate(newPassword);
      if (policyError != null) {
        state = state.copyWith(error: policyError);
        return false;
      }
      if (state.usuario?.idUsuario != null) {
        await _authService.changePassword(
          state.usuario!.idUsuario!,
          newPassword,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authService = ref.watch(authServiceProvider);
    return AuthController(authService);
  },
);

final currentUserProvider = Provider<Usuario?>((ref) {
  return ref.watch(authControllerProvider).usuario;
});
