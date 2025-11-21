class PedidoHistorial {
  final int? idHistorial;
  final int idPedido;
  final int idEstado;
  final DateTime fecha;
  final String? nombreEstado;
  final String? comentario;

  PedidoHistorial({
    this.idHistorial,
    required this.idPedido,
    required this.idEstado,
    required this.fecha,
    this.nombreEstado,
    this.comentario,
  });

  factory PedidoHistorial.fromJson(Map<String, dynamic> json) {
    return PedidoHistorial(
      idHistorial: json['id_historial'] as int?,
      idPedido: json['id_pedido'] as int,
      idEstado: json['id_estado'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      nombreEstado: json['nombre_estado'] as String?,
      comentario: json['comentario'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_historial': idHistorial,
      'id_pedido': idPedido,
      'id_estado': idEstado,
      'fecha': fecha.toIso8601String(),
      'comentario': comentario,
    };
  }
}