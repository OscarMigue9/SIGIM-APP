import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Script de integracion: consulta detalle de pedidos y devuelve JSON plano
/// con campos: nombre_producto, id_producto, nombre_cliente, precio_unitario,
/// id_cliente, fecha, cantidad, estado.
///
/// Ejecuci�n:
/// SUPABASE_URL=... SUPABASE_ANON_KEY=... dart run tools/integracion.dart
/// o en PowerShell:
///  $env:SUPABASE_URL="..."; $env:SUPABASE_ANON_KEY="..."; dart run tools/integracion.dart
Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_ANON_KEY'];
  if (url == null || key == null) {
    stderr.writeln('Faltan SUPABASE_URL y SUPABASE_ANON_KEY en variables de entorno');
    exit(1);
  }

  final client = SupabaseClient(url, key);

  // Consulta detalle_pedido con joins a pedido, estado, producto y cliente
  final data = await client
      .from('detalle_pedido')
      .select('''
        id_producto,
        cantidad,
        precio_unitario,
        pedido:pedido!inner (
          id_pedido,
          fecha_creacion,
          id_cliente,
          estado_pedido:id_estado ( nombre_estado ),
          cliente:usuario!pedido_id_cliente_fkey ( nombre, apellido )
        ),
        producto:producto!detalle_pedido_id_producto_fkey ( nombre )
      ''');

  final List<dynamic> rows = data as List<dynamic>;

  final mapped = rows.map((row) {
    final pedido = row['pedido'] ?? {};
    final estado = pedido['estado_pedido'] ?? {};
    final cliente = pedido['cliente'] ?? {};
    final producto = row['producto'] ?? {};
    return {
      'id_producto': row['id_producto'],
      'nombre_producto': producto['nombre'],
      'id_cliente': pedido['id_cliente'],
      'nombre_cliente': [cliente['nombre'], cliente['apellido']].where((e) => e != null && e.toString().isNotEmpty).join(' ').trim(),
      'precio_unitario': row['precio_unitario'],
      'cantidad': row['cantidad'],
      'fecha': pedido['fecha_creacion'],
      'estado': estado['nombre_estado'],
    };
  }).toList();

  // Imprimir JSON
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(mapped));
}
