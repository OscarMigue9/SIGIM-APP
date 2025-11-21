class IntegracionEntrega {
  final int idProducto;
  final String nombreProducto;
  final int idCliente;
  final String nombreCliente;
  final double precioUnitario;
  final int cantidad;
  final String estado;
  final DateTime fecha;

  IntegracionEntrega({
    required this.idProducto,
    required this.nombreProducto,
    required this.idCliente,
    required this.nombreCliente,
    required this.precioUnitario,
    required this.cantidad,
    required this.estado,
    required this.fecha,
  });

  factory IntegracionEntrega.fromJson(Map<String, dynamic> json) {
    return IntegracionEntrega(
      idProducto: json['id_producto'] as int,
      nombreProducto: json['nombre_producto'] as String? ?? 'Producto',
      idCliente: json['id_cliente'] as int,
      nombreCliente: json['nombre_cliente'] as String? ?? 'Cliente',
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
      estado: (json['estado'] as String? ?? '').toUpperCase(),
      fecha:
          DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
