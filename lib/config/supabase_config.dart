// Configuración de Supabase
//
// Las credenciales se inyectan por variables de entorno/Dart-define.
// Ejemplo:
// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
// flutter build apk ... --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
