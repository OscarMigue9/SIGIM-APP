class DetallePedido {
  final int? idDetalle;
  final int idPedido;
  final int idProducto;
  final int cantidad;
  final double precioUnitario;
  final String? nombreProducto;
  final String? skuProducto;

  DetallePedido({
    this.idDetalle,
    required this.idPedido,
    required this.idProducto,
    required this.cantidad,
    required this.precioUnitario,
    this.nombreProducto,
    this.skuProducto,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      idDetalle: json['id_detalle'] as int?,
      idPedido: json['id_pedido'] as int,
      idProducto: json['id_producto'] as int,
      cantidad: json['cantidad'] as int,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      nombreProducto: json['nombre_producto'] as String?,
      skuProducto: json['sku_producto'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_detalle': idDetalle,
      'id_pedido': idPedido,
      'id_producto': idProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      if (nombreProducto != null) 'nombre_producto': nombreProducto,
      if (skuProducto != null) 'sku_producto': skuProducto,
    };
  }

  double get subtotal => cantidad * precioUnitario;
}
