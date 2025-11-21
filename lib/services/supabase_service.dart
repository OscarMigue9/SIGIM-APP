import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  SupabaseClient? _client;
  
  // Evita acceder al cliente sin inicializar para obtener un error claro
  SupabaseClient get client {
    final client = _client;
    if (client == null) {
      throw StateError(
        'SupabaseService no ha sido inicializado. '
        'Llama a initialize() antes de usar los servicios.',
      );
    }
    return client;
  }
  
  bool get isInitialized => _client != null;
  
  Future<void> initialize() async {
    // Idempotente: si ya se inicializó, no hace nada
    if (_client != null) return;
    
    if (!SupabaseConfig.isConfigured) {
      throw Exception(
        'Supabase no configurado. '
        'Por favor actualiza las credenciales en lib/config/supabase_config.dart'
      );
    }
    
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }
  
  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  // Stream para cambios de autenticación
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
