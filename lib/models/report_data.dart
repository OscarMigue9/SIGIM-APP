import 'dart:typed_data';

class ReportData {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  // KPIs
  final int totalProductos;
  final int productosStockBajo;
  final double ventasMesActual;

  // Top productos por unidades vendidas
  // Estructura: [{"nombre": String, "totalVendido": int, "precio": double?}]
  final List<Map<String, dynamic>> topProductos;
  final List<Map<String, dynamic>> ventasPorDia; // cada item: {fecha: DateTime, total: double}
  final List<Map<String, dynamic>> ingresosPorCategoria; // {categoria, ingresos}
  final List<Map<String, dynamic>> pedidosPorEstado; // {estado, cantidad}

  // Imagen opcional de la gráfica (PNG bytes)
  final Uint8List? graficaPng;
  final Uint8List? graficaVentasDiaPng;
  final Uint8List? graficaCategoriasPng;
  final Uint8List? graficaEstadosPng;

  const ReportData({
    this.fechaInicio,
    this.fechaFin,
    required this.totalProductos,
    required this.productosStockBajo,
    required this.ventasMesActual,
    required this.topProductos,
    required this.ventasPorDia,
    required this.ingresosPorCategoria,
    required this.pedidosPorEstado,
    this.graficaPng,
    this.graficaVentasDiaPng,
    this.graficaCategoriasPng,
    this.graficaEstadosPng,
  });
}
