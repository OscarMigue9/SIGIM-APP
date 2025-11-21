import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido.dart';
import '../models/producto.dart';
import 'supabase_service.dart';

class ClienteService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Obtener productos para la tienda (todos los productos disponibles)
  Future<List<Producto>> obtenerProductosTienda() async {
    try {
      final response = await _client
          .from('producto')
          .select()
          .gt('stock', 0) // Solo productos con stock
          .order('nombre');

      return (response as List)
          .map((json) => Producto.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  // Obtener productos por categoría
  Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    try {
      final response = await _client
          .from('producto')
          .select()
          .eq('categoria', categoria)
          .gt('stock', 0)
          .order('nombre');

      return (response as List)
          .map((json) => Producto.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos por categoría: $e');
    }
  }

  // Obtener categorías disponibles
  Future<List<String>> obtenerCategorias() async {
    try {
      final response = await _client
          .from('producto')
          .select('categoria')
          .gt('stock', 0);

      final categorias = <String>{};
      for (final item in response) {
        if (item['categoria'] != null) {
          categorias.add(item['categoria'].toString());
        }
      }

      final listaOrdenada = categorias.toList()..sort();
      return listaOrdenada;
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  // Buscar productos
  Future<List<Producto>> buscarProductos(String query) async {
    try {
      final response = await _client
          .from('producto')
          .select()
          .or('nombre.ilike.%$query%,categoria.ilike.%$query%,sku.ilike.%$query%')
          .gt('stock', 0)
          .order('nombre');

      return (response as List)
          .map((json) => Producto.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar productos: $e');
    }
  }

  // Obtener pedidos del cliente actual
  Future<List<Pedido>> obtenerPedidosCliente(int idCliente) async {
    try {
      final response = await _client
          .from('pedido')
          .select('''
            *,
            estado_pedido!inner(nombre_estado),
            detalle_pedido(
              *,
              producto!inner(nombre, precio)
            )
          ''')
          .eq('id_cliente', idCliente)
          .order('fecha_creacion', ascending: false);

      return (response as List).map((json) {
        return Pedido.fromJson({
          ...json,
          'nombre_estado': json['estado_pedido']['nombre_estado'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos del cliente: $e');
    }
  }

  // Crear nuevo pedido
  Future<Pedido> crearPedido({
    required int idCliente,
    required List<Map<String, dynamic>> items, // {id_producto, cantidad, precio_unitario}
    required double total,
  }) async {
    try {
      // Verificar stock antes de crear el pedido
      for (final item in items) {
        final producto = await _client
            .from('producto')
            .select('stock')
            .eq('id_producto', item['id_producto'])
            .single();
        
        if (producto['stock'] < item['cantidad']) {
          throw Exception('Stock insuficiente para el producto ${item['id_producto']}');
        }
      }

      // Crear el pedido
      final pedidoResponse = await _client
          .from('pedido')
          .insert({
            'id_cliente': idCliente,
            'fecha_creacion': DateTime.now().toIso8601String(),
            'id_estado': 1, // Pendiente
            'total': total,
          })
          .select()
          .single();

      final idPedido = pedidoResponse['id_pedido'];

      // Crear los detalles del pedido
      final detalles = items.map((item) => {
        'id_pedido': idPedido,
        'id_producto': item['id_producto'],
        'cantidad': item['cantidad'],
        'precio_unitario': item['precio_unitario'],
      }).toList();

      await _client
          .from('detalle_pedido')
          .insert(detalles);

      // Actualizar stock de productos
      for (final item in items) {
        await _client
            .from('producto')
            .update({
              'stock': await _client
                  .from('producto')
                  .select('stock')
                  .eq('id_producto', item['id_producto'])
                  .single()
                  .then((response) => response['stock'] - item['cantidad'])
            })
            .eq('id_producto', item['id_producto']);
      }

      // Obtener el pedido completo creado
      final pedidoCompleto = await _client
          .from('pedido')
          .select('''
            *,
            estado_pedido!inner(nombre_estado)
          ''')
          .eq('id_pedido', idPedido)
          .single();

      return Pedido.fromJson({
        ...pedidoCompleto,
        'nombre_estado': pedidoCompleto['estado_pedido']['nombre_estado'],
      });
    } catch (e) {
      throw Exception('Error al crear pedido: $e');
    }
  }

  // Crear pedido con datos de checkout avanzados (entrega y pago)
  Future<Pedido> crearPedidoAvanzado({
    required int idCliente,
    required List<Map<String, dynamic>> items,
    required double total,
    required String tipoEntrega, // 'envio' | 'retiro'
    String? direccionEnvio,
    required String metodoPago, // 'tarjeta' | 'transferencia' | 'efectivo'
    String? pagoReferencia,
  }) async {
    try {
      // Verificar stock
      for (final item in items) {
        final producto = await _client
            .from('producto')
            .select('stock')
            .eq('id_producto', item['id_producto'])
            .single();
        if (producto['stock'] < item['cantidad']) {
          throw Exception('Stock insuficiente para el producto ${item['id_producto']}');
        }
      }

      Map<String, dynamic> pedidoInsert = {
        'id_cliente': idCliente,
        'fecha_creacion': DateTime.now().toIso8601String(),
        'id_estado': 1,
        'total': total,
      };

      // Intentar columnas avanzadas; si no existen, fallback luego
      pedidoInsert['tipo_entrega'] = tipoEntrega; // requiere ALTER TABLE
      if (direccionEnvio != null) pedidoInsert['direccion_envio'] = direccionEnvio;
      pedidoInsert['metodo_pago'] = metodoPago;
      if (pagoReferencia != null) pedidoInsert['pago_referencia'] = pagoReferencia;

      dynamic pedidoResponse;
      try {
        pedidoResponse = await _client.from('pedido').insert(pedidoInsert).select().single();
      } catch (_) {
        // Fallback: crear sin columnas extra
        pedidoResponse = await _client
            .from('pedido')
            .insert({
              'id_cliente': idCliente,
              'fecha_creacion': DateTime.now().toIso8601String(),
              'id_estado': 1,
              'total': total,
            })
            .select()
            .single();
      }

      final idPedido = pedidoResponse['id_pedido'];

      // Insertar detalles
      final detalles = items.map((item) => {
        'id_pedido': idPedido,
        'id_producto': item['id_producto'],
        'cantidad': item['cantidad'],
        'precio_unitario': item['precio_unitario'],
      }).toList();
      await _client.from('detalle_pedido').insert(detalles);

      // Actualizar stock
      for (final item in items) {
        await _client
            .from('producto')
            .update({
              'stock': await _client
                  .from('producto')
                  .select('stock')
                  .eq('id_producto', item['id_producto'])
                  .single()
                  .then((r) => r['stock'] - item['cantidad'])
            })
            .eq('id_producto', item['id_producto']);
      }

      final pedidoCompleto = await _client
          .from('pedido')
          .select('''
            *,
            estado_pedido!inner(nombre_estado)
          ''')
          .eq('id_pedido', idPedido)
          .single();

      return Pedido.fromJson({
        ...pedidoCompleto,
        'nombre_estado': pedidoCompleto['estado_pedido']['nombre_estado'],
      });
    } catch (e) {
      throw Exception('Error al crear pedido (checkout): $e');
    }
  }

  // Obtener detalles de un producto específico
  Future<Producto?> obtenerProductoPorId(int idProducto) async {
    try {
      final response = await _client
          .from('producto')
          .select()
          .eq('id_producto', idProducto)
          .single();

      return Producto.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  // Obtener productos destacados (los más vendidos o con mejor margen)
  Future<List<Producto>> obtenerProductosDestacados({int limit = 6}) async {
    try {
      final response = await _client
          .from('producto')
          .select()
          .gt('stock', 0)
          .order('precio', ascending: false) // Por precio descendente como "destacados"
          .limit(limit);

      return (response as List)
          .map((json) => Producto.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos destacados: $e');
    }
  }
}