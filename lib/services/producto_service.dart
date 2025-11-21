import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';
import 'supabase_service.dart';

class ProductoService {
  final SupabaseClient _client = SupabaseService.instance.client;
  static const _table = 'producto';

  // REQ-002: CRUD sobre tabla producto
  Future<List<Producto>> obtenerProductos() async {
    try {
      final response = await _client.from(_table).select().order('nombre');

      return (response as List).map((json) => Producto.fromJson(json)).toList();
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al obtener productos', e));
    }
  }

  Future<Producto?> obtenerProductoPorId(int id) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('id_producto', id)
          .single();

      return Producto.fromJson(response);
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al obtener producto', e));
    }
  }

  Future<List<Producto>> buscarProductos(String query) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .or(
            'nombre.ilike.%$query%,sku.ilike.%$query%,categoria.ilike.%$query%',
          )
          .order('nombre');

      return (response as List).map((json) => Producto.fromJson(json)).toList();
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al buscar productos', e));
    }
  }

  Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('categoria', categoria)
          .order('nombre');

      return (response as List).map((json) => Producto.fromJson(json)).toList();
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al filtrar por categoría', e));
    }
  }

  Future<Producto> crearProducto(Producto producto) async {
    try {
      // Validar SKU único
      final existingSku = await _client
          .from(_table)
          .select('sku')
          .eq('sku', producto.sku);

      if (existingSku.isNotEmpty) {
        throw Exception('El SKU ${producto.sku} ya existe');
      }

      final payload = _buildInsertPayload(producto);
      final response = await _client
          .from(_table)
          .insert(payload)
          .select()
          .single();

      return Producto.fromJson(response);
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al crear producto', e));
    }
  }

  Future<Producto> actualizarProducto(Producto producto) async {
    try {
      if (producto.idProducto == null) {
        throw Exception('ID de producto requerido para actualizar');
      }

      // Validar SKU único (excluyendo el producto actual)
      final existingSku = await _client
          .from(_table)
          .select('id_producto, sku')
          .eq('sku', producto.sku)
          .neq('id_producto', producto.idProducto!);

      if (existingSku.isNotEmpty) {
        throw Exception('El SKU ${producto.sku} ya existe en otro producto');
      }

      final payload = _buildUpdatePayload(producto);
      final response = await _client
          .from(_table)
          .update(payload)
          .eq('id_producto', producto.idProducto!)
          .select()
          .single();

      return Producto.fromJson(response);
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al actualizar producto', e));
    }
  }

  Future<void> eliminarProducto(int idProducto) async {
    try {
      // Verificar si el producto tiene pedidos asociados
      final pedidosAsociados = await _client
          .from('detalle_pedido')
          .select('id_detalle')
          .eq('id_producto', idProducto);

      if (pedidosAsociados.isNotEmpty) {
        throw Exception(
          'No se puede eliminar el producto porque tiene pedidos asociados',
        );
      }

      await _client.from(_table).delete().eq('id_producto', idProducto);
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al eliminar producto', e));
    }
  }

  // REQ-003: Gestión de stock
  Future<List<Producto>> obtenerProductosConStockBajo({int limite = 5}) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .lte('stock', limite)
          .order('stock');

      return (response as List).map((json) => Producto.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        _buildErrorMessage('Error al obtener productos con stock bajo', e),
      );
    }
  }

  Future<bool> actualizarStock(int idProducto, int nuevoStock) async {
    try {
      await _client
          .from(_table)
          .update({'stock': nuevoStock})
          .eq('id_producto', idProducto);
      return true;
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al actualizar stock', e));
    }
  }

  Future<bool> reducirStock(int idProducto, int cantidad) async {
    try {
      // Obtener stock actual
      final producto = await obtenerProductoPorId(idProducto);
      if (producto == null) {
        throw Exception('Producto no encontrado');
      }

      if (producto.stock < cantidad) {
        throw Exception('Stock insuficiente. Disponible: ${producto.stock}');
      }

      final nuevoStock = producto.stock - cantidad;
      return await actualizarStock(idProducto, nuevoStock);
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al reducir stock', e));
    }
  }

  Future<List<String>> obtenerCategorias() async {
    try {
      final response = await _client
          .from(_table)
          .select('categoria')
          .order('categoria');

      final categorias = <String>{};
      for (final item in response) {
        categorias.add(item['categoria'] as String);
      }

      return categorias.toList();
    } catch (e) {
      throw Exception(_buildErrorMessage('Error al obtener categorías', e));
    }
  }

  Map<String, dynamic> _buildInsertPayload(Producto producto) {
    final data = producto.toJson()
      ..remove('id_producto')
      ..removeWhere((_, value) => value == null);
    return data;
  }

  Map<String, dynamic> _buildUpdatePayload(Producto producto) {
    final data = producto.toJson()..remove('id_producto');
    return data;
  }

  String _buildErrorMessage(String context, Object error) {
    final detail = _extractErrorDetail(error);
    if (detail.isEmpty) return context;
    return '$context: $detail';
  }

  String _extractErrorDetail(Object error) {
    if (error is PostgrestException) {
      final parts = <String>[];

      if (error.code == '23505') {
        parts.add('Registro duplicado');
      } else if (error.code == '23502') {
        parts.add('Falta un campo obligatorio');
      }

      final message = error.message.toString().trim();
      final details = (error.details ?? '').toString().trim();
      final hint = (error.hint ?? '').toString().trim();

      if (message.isNotEmpty) parts.add(message);
      if (details.isNotEmpty) parts.add(details);
      if (hint.isNotEmpty) parts.add(hint);

      return parts.join(' - ');
    }

    return error.toString().replaceAll('Exception: ', '').trim();
  }
}
