import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class DireccionPagoService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Direcciones
  Future<List<Map<String, dynamic>>> obtenerDireccionesUsuario(int idUsuario) async {
    final res = await _client
        .from('direccion_usuario')
        .select()
        .eq('id_usuario', idUsuario)
        .order('es_default', ascending: false)
        .order('id_direccion');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>> crearDireccion({
    required int idUsuario,
    required String linea1,
    String? linea2,
    required String ciudad,
    required String provincia,
    required String cp,
    String? referencias,
    bool esDefault = false,
  }) async {
    final res = await _client
        .from('direccion_usuario')
        .insert({
          'id_usuario': idUsuario,
          'linea1': linea1,
          'linea2': linea2,
            'ciudad': ciudad,
          'provincia': provincia,
          'cp': cp,
          'referencias': referencias,
          'es_default': esDefault,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> actualizarDireccion({
    required int idDireccion,
    required int idUsuario,
    required String linea1,
    String? linea2,
    required String ciudad,
    required String provincia,
    required String cp,
    String? referencias,
    bool esDefault = false,
  }) async {
    final res = await _client
        .from('direccion_usuario')
        .update({
          'linea1': linea1,
          'linea2': linea2,
          'ciudad': ciudad,
          'provincia': provincia,
          'cp': cp,
          'referencias': referencias,
          'es_default': esDefault,
        })
        .eq('id_direccion', idDireccion)
        .eq('id_usuario', idUsuario)
        .select()
        .single();
    return Map<String, dynamic>.from(res);
  }

  Future<void> eliminarDireccion(int idDireccion, int idUsuario) async {
    await _client
        .from('direccion_usuario')
        .delete()
        .eq('id_direccion', idDireccion)
        .eq('id_usuario', idUsuario);
  }

  // Métodos de pago
  Future<List<Map<String, dynamic>>> obtenerMetodosPagoUsuario(int idUsuario) async {
    final res = await _client
        .from('metodo_pago_usuario')
        .select()
        .eq('id_usuario', idUsuario)
        .order('es_default', ascending: false)
        .order('id_metodo');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>> crearMetodoPago({
    required int idUsuario,
    required String tipo, // tarjeta | transferencia | efectivo | nequi
    String? alias,
    Map<String, dynamic>? datos,
    bool esDefault = false,
  }) async {
    final res = await _client
        .from('metodo_pago_usuario')
        .insert({
          'id_usuario': idUsuario,
          'tipo': tipo,
          'alias': alias,
          'datos': datos,
          'es_default': esDefault,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> actualizarMetodoPago({
    required int idMetodo,
    required int idUsuario,
    String? alias,
    Map<String, dynamic>? datos,
    bool? esDefault,
  }) async {
    final update = <String, dynamic>{};
    if (alias != null) update['alias'] = alias;
    if (datos != null) update['datos'] = datos;
    if (esDefault != null) update['es_default'] = esDefault;
    final res = await _client
        .from('metodo_pago_usuario')
        .update(update)
        .eq('id_metodo', idMetodo)
        .eq('id_usuario', idUsuario)
        .select()
        .single();
    return Map<String, dynamic>.from(res);
  }

  Future<void> eliminarMetodoPago(int idMetodo, int idUsuario) async {
    await _client
        .from('metodo_pago_usuario')
        .delete()
        .eq('id_metodo', idMetodo)
        .eq('id_usuario', idUsuario);
  }
}
