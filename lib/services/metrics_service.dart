import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class MetricsService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Obtener métricas del dashboard del admin
  Future<Map<String, dynamic>> getAdminMetrics() async {
    try {
      // Contar usuarios totales
      final usuariosResponse = await _client
          .from('usuario')
          .select('id_usuario');
      
      // Contar productos totales
      final productosResponse = await _client
          .from('producto')
          .select('id_producto');
      
      // Contar pedidos de hoy
      final hoy = DateTime.now().toIso8601String().split('T')[0];
      final pedidosHoyResponse = await _client
          .from('pedido')
          .select('id_pedido')
          .gte('fecha_creacion', '${hoy}T00:00:00')
          .lte('fecha_creacion', '${hoy}T23:59:59');
      
      // Calcular ventas del mes
      final inicioMes = DateTime(DateTime.now().year, DateTime.now().month, 1)
          .toIso8601String().split('T')[0];
      final ventasResponse = await _client
          .from('pedido')
          .select('total')
          .gte('fecha_creacion', '${inicioMes}T00:00:00');
      
      double totalVentas = 0;
      for (final venta in ventasResponse) {
        totalVentas += (venta['total'] as num).toDouble();
      }

      return {
        'totalUsuarios': usuariosResponse.length,
        'totalProductos': productosResponse.length,
        'pedidosHoy': pedidosHoyResponse.length,
        'ventasMes': totalVentas,
      };
    } catch (e) {
      throw Exception('Error al obtener métricas del admin: $e');
    }
  }

  // Obtener métricas del vendedor
  Future<Map<String, dynamic>> getVendedorMetrics(int idVendedor) async {
    try {
      final hoy = DateTime.now().toIso8601String().split('T')[0];
      
      // Pedidos de hoy del vendedor (asumiendo que hay un campo id_vendedor en pedido)
      // Si no existe, usaremos todos los pedidos de hoy
      dynamic pedidosQuery = _client
          .from('pedido')
          .select('id_pedido, total')
          .gte('fecha_creacion', '${hoy}T00:00:00')
          .lte('fecha_creacion', '${hoy}T23:59:59');
      try {
        // Intentar filtrar por id_vendedor (si la columna existe)
        pedidosQuery = pedidosQuery.eq('id_vendedor', idVendedor);
      } catch (_) {
        // Ignorar si falla por columna inexistente
      }
      final pedidosHoyResponse = await pedidosQuery;
      
      double ventasHoy = 0;
      for (final pedido in pedidosHoyResponse) {
        ventasHoy += (pedido['total'] as num).toDouble();
      }

      return {
        'ventasHoy': ventasHoy,
        'pedidosHoy': pedidosHoyResponse.length,
      };
    } catch (e) {
      throw Exception('Error al obtener métricas del vendedor: $e');
    }
  }

  // Obtener actividad reciente
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 5}) async {
    try {
      List<Map<String, dynamic>> actividades = [];

      // Últimos usuarios registrados (ordenar por ID ya que no hay created_at)
      final usuariosRecientes = await _client
          .from('usuario')
          .select('id_usuario, nombre, apellido')
          .order('id_usuario', ascending: false)
          .limit(3);

      for (final usuario in usuariosRecientes) {
        actividades.add({
          'tipo': 'usuario',
          'titulo': 'Usuario registrado',
          'descripcion': '${usuario['nombre']} ${usuario['apellido']} (ID: ${usuario['id_usuario']})',
          'fecha': DateTime.now().subtract(Duration(hours: usuario['id_usuario'] % 24)).toIso8601String(),
          'icon': 'person_add',
        });
      }

      // Últimos pedidos
        // Desambiguar relación usuario ahora que existe id_vendedor e id_cliente
        final pedidosRecientes = await _client
          .from('pedido')
          .select('id_pedido, total, fecha_creacion, usuario:usuario!pedido_id_cliente_fkey (nombre, apellido)')
          .order('fecha_creacion', ascending: false)
          .limit(3);

      for (final pedido in pedidosRecientes) {
        final usuario = pedido['usuario'];
        actividades.add({
          'tipo': 'pedido',
          'titulo': 'Nuevo pedido',
          'descripcion': 'Pedido #${pedido['id_pedido']} por \$${pedido['total']} - ${usuario['nombre']} ${usuario['apellido']}',
          'fecha': pedido['fecha_creacion'],
          'icon': 'shopping_cart',
        });
      }

      // Productos con stock actualizado recientemente (si tienes un campo updated_at)
      // Por ahora usaremos productos con stock bajo
      final productosStockBajo = await _client
          .from('producto')
          .select('nombre, stock')
          .lte('stock', 10)
          .limit(2);

      for (final producto in productosStockBajo) {
        actividades.add({
          'tipo': 'stock',
          'titulo': 'Stock bajo',
          'descripcion': 'Producto "${producto['nombre']}" - ${producto['stock']} unidades',
          'fecha': DateTime.now().toIso8601String(),
          'icon': 'inventory_2',
        });
      }

      // Ordenar por fecha y limitar
      actividades.sort((a, b) => DateTime.parse(b['fecha']).compareTo(DateTime.parse(a['fecha'])));
      
      return actividades.take(limit).toList();
    } catch (e) {
      throw Exception('Error al obtener actividad reciente: $e');
    }
  }

  // Obtener ventas recientes para vendedor
  Future<List<Map<String, dynamic>>> getRecentSales({int limit = 5}) async {
    try {
      final ventasRecientes = await _client
          .from('pedido')
          .select('''
            id_pedido, 
            total, 
            fecha_creacion,
            usuario:usuario!pedido_id_cliente_fkey (nombre, apellido),
            detalle_pedido(cantidad)
          ''')
          .order('fecha_creacion', ascending: false)
          .limit(limit);

      return ventasRecientes.map<Map<String, dynamic>>((venta) {
        final usuario = venta['usuario'];
        final detalles = venta['detalle_pedido'] as List;
        final totalProductos = detalles.fold<int>(0, (sum, detalle) => sum + (detalle['cantidad'] as int));
        
        return {
          'nombreCliente': '${usuario['nombre']} ${usuario['apellido']}',
          'total': venta['total'],
          'productos': '$totalProductos productos',
          'fecha': venta['fecha_creacion'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener ventas recientes: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentSalesVendedor(int idVendedor, {int limit = 5}) async {
    try {
      dynamic query = _client
          .from('pedido')
          .select('''
            id_pedido,
            total,
            fecha_creacion,
            usuario:usuario!pedido_id_cliente_fkey (nombre, apellido),
            detalle_pedido(cantidad)
          ''');
      try {
        // Aplica el filtro primero, luego ordena/limita
        query = query.eq('id_vendedor', idVendedor).order('fecha_creacion', ascending: false).limit(limit);
      } catch (_) {
        // Si la columna no existe, devolvemos lista vacía para evitar confusión
        // Fallback: usar ventas recientes sin filtrar
        return getRecentSales(limit: limit);
      }
      final ventasRecientes = await query;
      // Fallback: si no hay resultados (p.ej. pedidos sin id_vendedor), usar ventas recientes generales
      if (ventasRecientes is List && ventasRecientes.isEmpty) {
        return getRecentSales(limit: limit);
      }
      return ventasRecientes.map<Map<String, dynamic>>((venta) {
        final usuario = venta['usuario'];
        final detalles = venta['detalle_pedido'] as List;
        final totalProductos = detalles.fold<int>(0, (sum, detalle) => sum + (detalle['cantidad'] as int));
        return {
          'nombreCliente': '${usuario['nombre']} ${usuario['apellido']}',
          'total': venta['total'],
          'productos': '$totalProductos productos',
          'fecha': venta['fecha_creacion'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener ventas del vendedor: $e');
    }
  }

  // Obtener productos más vendidos
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5, DateTime? inicio, DateTime? fin}) async {
    try {
      // Intentar RPC si no hay filtros de fecha
      if (inicio == null && fin == null) {
        final response = await _client
            .rpc('get_productos_mas_vendidos', params: {'limite': limit});
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (_) {
      // Ignorar error de RPC y pasar a cálculo manual
    }

    try {
      // Si hay rango, primero obtener pedidos dentro de rango para limitar detalles
      List<int>? pedidosIds;
      if (inicio != null || fin != null) {
        var pedidosQuery = _client.from('pedido').select('id_pedido, fecha_creacion');
        if (inicio != null) {
          pedidosQuery = pedidosQuery.gte('fecha_creacion', inicio.toIso8601String());
        }
        if (fin != null) {
          pedidosQuery = pedidosQuery.lte('fecha_creacion', fin.toIso8601String());
        }
        final pedidosResponse = await pedidosQuery;
        pedidosIds = pedidosResponse.map<int>((p) => p['id_pedido'] as int).toList();
        if (pedidosIds.isEmpty) return [];
      }

      var detallesQuery = _client
          .from('detalle_pedido')
          .select('''
            cantidad,
            id_pedido,
            producto!inner(nombre, precio)
          ''');

      if (pedidosIds != null) {
        detallesQuery = detallesQuery.inFilter('id_pedido', pedidosIds);
      }

      final ventasProductos = await detallesQuery;

      Map<String, Map<String, dynamic>> productosVentas = {};
      for (final detalle in ventasProductos) {
        final producto = detalle['producto'];
        final nombreProducto = producto['nombre'];
        final cantidad = detalle['cantidad'] as int;
        final precio = (producto['precio'] as num?)?.toDouble() ?? 0.0;

        if (productosVentas.containsKey(nombreProducto)) {
          productosVentas[nombreProducto]!['totalVendido'] += cantidad;
        } else {
          productosVentas[nombreProducto] = {
            'nombre': nombreProducto,
            'precio': precio,
            'totalVendido': cantidad,
          };
        }
      }

      final sortedProducts = productosVentas.values.toList()
        ..sort((a, b) => (b['totalVendido'] as int).compareTo(a['totalVendido'] as int));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Error al obtener productos más vendidos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVentasPorDia({DateTime? inicio, DateTime? fin}) async {
    try {
      var query = _client.from('pedido').select('fecha_creacion,total');
      if (inicio != null) {
        query = query.gte('fecha_creacion', inicio.toIso8601String());
      }
      if (fin != null) {
        // Ajustar fin al final del día si viene sin hora
        final finAjustado = fin.hour == 0 && fin.minute == 0
            ? fin.add(const Duration(hours: 23, minutes: 59, seconds: 59))
            : fin;
        query = query.lte('fecha_creacion', finAjustado.toIso8601String());
      }
      final pedidos = await query;

      final Map<DateTime, double> acumulado = {};
      for (final p in pedidos) {
        final fecha = DateTime.parse(p['fecha_creacion']);
        final dia = DateTime(fecha.year, fecha.month, fecha.day);
        final total = (p['total'] as num?)?.toDouble() ?? 0.0;
        acumulado[dia] = (acumulado[dia] ?? 0) + total;
      }

      final diasOrdenados = acumulado.keys.toList()..sort();
      return diasOrdenados.map((d) => {
            'fecha': d,
            'total': acumulado[d]!.toDouble(),
          }).toList();
    } catch (e) {
      throw Exception('Error al obtener ventas por día: $e');
    }
  }

  // Ingresos por categoría (para pie chart)
  Future<List<Map<String, dynamic>>> getIngresosPorCategoria({DateTime? inicio, DateTime? fin}) async {
    try {
      // Limitar por pedidos del rango si aplica
      List<int>? pedidosIds;
      if (inicio != null || fin != null) {
        var pedidosQuery = _client.from('pedido').select('id_pedido, fecha_creacion');
        if (inicio != null) pedidosQuery = pedidosQuery.gte('fecha_creacion', inicio.toIso8601String());
        if (fin != null) {
          final finAdj = fin.hour == 0 && fin.minute == 0
              ? fin.add(const Duration(hours: 23, minutes: 59, seconds: 59))
              : fin;
          pedidosQuery = pedidosQuery.lte('fecha_creacion', finAdj.toIso8601String());
        }
        final pedidos = await pedidosQuery;
        pedidosIds = pedidos.map<int>((p) => p['id_pedido'] as int).toList();
        if (pedidosIds.isEmpty) return [];
      }

      var detallesQuery = _client
          .from('detalle_pedido')
          .select('''
            cantidad,
            id_pedido,
            producto!inner(nombre, precio, categoria)
          ''');
      if (pedidosIds != null) {
        detallesQuery = detallesQuery.inFilter('id_pedido', pedidosIds);
      }
      final detalles = await detallesQuery;

      final Map<String, double> ingresosPorCat = {};
      for (final d in detalles) {
        final cat = (d['producto']['categoria'] as String?) ?? 'Sin categoría';
        final precio = (d['producto']['precio'] as num?)?.toDouble() ?? 0;
        final cant = (d['cantidad'] as num?)?.toDouble() ?? 0;
        ingresosPorCat[cat] = (ingresosPorCat[cat] ?? 0) + (precio * cant);
      }

      return ingresosPorCat.entries
          .map((e) => {'categoria': e.key, 'ingresos': e.value})
          .toList()
        ..sort((a, b) => (b['ingresos'] as double).compareTo(a['ingresos'] as double));
    } catch (e) {
      throw Exception('Error al obtener ingresos por categoría: $e');
    }
  }

  // Pedidos por estado (para donut)
  Future<List<Map<String, dynamic>>> getPedidosPorEstado({DateTime? inicio, DateTime? fin}) async {
    try {
      var query = _client
          .from('pedido')
          .select('id_estado, fecha_creacion, estado_pedido!inner(nombre_estado)');
      if (inicio != null) query = query.gte('fecha_creacion', inicio.toIso8601String());
      if (fin != null) {
        final finAdj = fin.hour == 0 && fin.minute == 0
            ? fin.add(const Duration(hours: 23, minutes: 59, seconds: 59))
            : fin;
        query = query.lte('fecha_creacion', finAdj.toIso8601String());
      }
      final pedidos = await query;

      final Map<String, int> conteo = {};
      for (final p in pedidos) {
        final nombre = (p['estado_pedido']?['nombre_estado'] as String?) ?? 'Desconocido';
        conteo[nombre] = (conteo[nombre] ?? 0) + 1;
      }

      return conteo.entries
          .map((e) => {'estado': e.key, 'cantidad': e.value})
          .toList()
        ..sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
    } catch (e) {
      throw Exception('Error al obtener pedidos por estado: $e');
    }
  }
}