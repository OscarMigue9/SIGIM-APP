import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ClienteContactoService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<Map<String, dynamic>> crearContacto({
    required String nombre,
    required String apellido,
    String? telefono,
    String? email,
  }) async {
    final res = await _client
        .from('cliente_contacto')
        .insert({
          'nombre': nombre,
          'apellido': apellido,
          if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
          if (email != null && email.isNotEmpty) 'email': email,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(res);
  }
}
