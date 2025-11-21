class AjusteInventario {
  final int? idAjuste;
  final int idProducto;
  final int? idUsuario; // Puede quedar NULL si el usuario se elimina
  final int delta; // Positivo para entrada, negativo para salida
  final int stockInicial;
  final int stockFinal;
  final String motivo;
  final DateTime fecha;

  AjusteInventario({
    this.idAjuste,
    required this.idProducto,
    required this.idUsuario,
    required this.delta,
    required this.stockInicial,
    required this.stockFinal,
    required this.motivo,
    required this.fecha,
  });

  factory AjusteInventario.fromJson(Map<String, dynamic> json) {
    return AjusteInventario(
      idAjuste: json['id_ajuste'] as int?,
      idProducto: json['id_producto'] as int,
      idUsuario: json['id_usuario'] as int?,
      delta: json['delta'] as int,
      stockInicial: json['stock_inicial'] as int,
      stockFinal: json['stock_final'] as int,
      motivo: json['motivo'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_ajuste': idAjuste,
      'id_producto': idProducto,
      'id_usuario': idUsuario,
      'delta': delta,
      'stock_inicial': stockInicial,
      'stock_final': stockFinal,
      'motivo': motivo,
      'fecha': fecha.toIso8601String(),
    };
  }

  bool get esEntrada => delta > 0;
  bool get esSalida => delta < 0;
  String get tipo => esEntrada ? 'ENTRADA' : 'SALIDA';
}
