import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/descuento.dart';

class DescuentoService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<Descuento?> obtenerPorCodigo(String codigo) async {
    final data = await _client.from('descuento').select().eq('codigo', codigo).maybeSingle();
    if (data == null) return null;
    return Descuento.fromJson(data);
  }

  Future<bool> incrementarUso(int idDescuento) async {
    await _client.rpc('incrementar_uso_descuento', params: {'p_id_descuento': idDescuento});
    return true;
  }

  Future<Descuento?> obtenerPorId(int id) async {
    final data = await _client.from('descuento').select().eq('id_descuento', id).maybeSingle();
    if (data == null) return null;
    return Descuento.fromJson(data);
  }

  bool esAplicable(Descuento d, double totalAntes, {int? idProducto, String? categoria}) {
    if (!d.activo) return false;
    final now = DateTime.now();
    if (d.fechaInicio != null && now.isBefore(d.fechaInicio!)) return false;
    if (d.fechaFin != null && now.isAfter(d.fechaFin!)) return false;
    if (d.minTotal != null && totalAntes < d.minTotal!) return false;
    if (d.usoMax != null && d.usoActual >= d.usoMax!) return false;
    if (d.idProducto != null && d.idProducto != idProducto) return false;
    if (d.categoria != null && d.categoria != categoria) return false;
    return true;
  }

  double calcularTotalConDescuento(Descuento d, double totalAntes) {
    if (d.esPorcentaje) {
      return (totalAntes - (totalAntes * (d.valor / 100))).clamp(0, double.infinity);
    } else {
      return (totalAntes - d.valor).clamp(0, double.infinity);
    }
  }
}
