class Descuento {
  final int? idDescuento;
  final String codigo;
  final String tipo; // PORCENTAJE o FIJO
  final double valor;
  final bool activo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double? minTotal;
  final int? idProducto;
  final String? categoria;
  final int? usoMax;
  final int usoActual;

  Descuento({
    this.idDescuento,
    required this.codigo,
    required this.tipo,
    required this.valor,
    this.activo = true,
    this.fechaInicio,
    this.fechaFin,
    this.minTotal,
    this.idProducto,
    this.categoria,
    this.usoMax,
    this.usoActual = 0,
  });

  factory Descuento.fromJson(Map<String,dynamic> json) => Descuento(
    idDescuento: json['id_descuento'] as int?,
    codigo: json['codigo'] as String,
    tipo: json['tipo'] as String,
    valor: (json['valor'] as num).toDouble(),
    activo: json['activo'] as bool? ?? true,
    fechaInicio: json['fecha_inicio'] != null ? DateTime.parse(json['fecha_inicio'] as String) : null,
    fechaFin: json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin'] as String) : null,
    minTotal: json['min_total'] != null ? (json['min_total'] as num).toDouble() : null,
    idProducto: json['id_producto'] as int?,
    categoria: json['categoria'] as String?,
    usoMax: json['uso_max'] as int?,
    usoActual: json['uso_actual'] as int? ?? 0,
  );

  Map<String,dynamic> toJson() => {
    'id_descuento': idDescuento,
    'codigo': codigo,
    'tipo': tipo,
    'valor': valor,
    'activo': activo,
    'fecha_inicio': fechaInicio?.toIso8601String(),
    'fecha_fin': fechaFin?.toIso8601String(),
    'min_total': minTotal,
    'id_producto': idProducto,
    'categoria': categoria,
    'uso_max': usoMax,
    'uso_actual': usoActual,
  };

  bool get esPorcentaje => tipo == 'PORCENTAJE';
}
