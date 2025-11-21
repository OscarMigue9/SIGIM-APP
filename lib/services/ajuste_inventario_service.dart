import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ajuste_inventario.dart';
import 'supabase_service.dart';

class AjusteInventarioService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<AjusteInventario> aplicarAjuste({
    required int idProducto,
    required int delta,
    required String motivo,
  }) async {
    if (delta == 0) {
      throw Exception('El delta no puede ser 0');
    }
    if (motivo.trim().isEmpty) {
      throw Exception('Motivo requerido');
    }
    try {
      final response = await _client.rpc('aplicar_ajuste_inventario', params: {
        'p_id_producto': idProducto,
        'p_delta': delta,
        'p_motivo': motivo,
      });
      return AjusteInventario.fromJson(response);
    } catch (e) {
      throw Exception('Error al aplicar ajuste: $e');
    }
  }

  Future<List<AjusteInventario>> listarAjustes({
    int? idProducto,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      var builder = _client.from('ajuste_inventario').select();
      if (idProducto != null) {
        builder = builder.eq('id_producto', idProducto);
      }
      if (desde != null) {
        builder = builder.gte('fecha', desde.toIso8601String());
      }
      if (hasta != null) {
        builder = builder.lte('fecha', hasta.toIso8601String());
      }
      final data = await builder.order('fecha', ascending: false);
      return (data as List).map((j) => AjusteInventario.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Error al listar ajustes: $e');
    }
  }
}
