import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/producto_controller.dart';
import '../../services/metrics_service.dart';
import '../../services/report_service.dart';
import '../../models/report_data.dart';
import '../../utils/chart_utils.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  final _fechaInicio = ValueNotifier<DateTime?>(null);
  final _fechaFin = ValueNotifier<DateTime?>(null);
  final _chartKey = GlobalKey(); // top productos
  final _pieCatKey = GlobalKey();
  final _donutKey = GlobalKey();

  final _metricsService = MetricsService();
  final _reportService = ReportService();
  bool _exporting = false;

  List<Map<String, dynamic>> _topProductos = const [];
  List<Map<String, dynamic>> _ventasPorDia = const [];
  List<Map<String, dynamic>> _ingresosPorCategoria = const [];
  List<Map<String, dynamic>> _pedidosPorEstado = const [];
  double _ventasMes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Cargar productos y métricas necesarias
    Future.microtask(() async {
      await ref.read(productoControllerProvider.notifier).cargarProductos();
      await _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final metrics = await _metricsService.getAdminMetrics();
      final top = await _metricsService.getTopProducts(
        limit: 5,
        inicio: _fechaInicio.value,
        fin: _fechaFin.value,
      );
      final serie = await _metricsService.getVentasPorDia(
        inicio: _fechaInicio.value,
        fin: _fechaFin.value,
      );
      final cat = await _metricsService.getIngresosPorCategoria(
        inicio: _fechaInicio.value,
        fin: _fechaFin.value,
      );
      final estados = await _metricsService.getPedidosPorEstado(
        inicio: _fechaInicio.value,
        fin: _fechaFin.value,
      );
      setState(() {
        _ventasMes = (metrics['ventasMes'] as num?)?.toDouble() ?? 0;
        _topProductos = top;
        _ventasPorDia = serie;
        _ingresosPorCategoria = cat;
        _pedidosPorEstado = estados;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Error cargando datos de reportes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productosState = ref.watch(productoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'PDF',
            onPressed: _loading || _exporting ? null : () => _generarPdf(productosState),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          PopupMenuButton<String>(
            tooltip: 'Exportar',
            enabled: !_loading && !_exporting,
            onSelected: (v) => _handleExport(v, productosState),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'productos_excel', child: Text('Productos Excel')),
              PopupMenuItem(value: 'productos_csv', child: Text('Productos CSV')),
              PopupMenuItem(value: 'pedidos_excel', child: Text('Pedidos Excel')),
              PopupMenuItem(value: 'pedidos_csv', child: Text('Pedidos CSV')),
              PopupMenuItem(value: 'ventas_excel', child: Text('Ventas/Día Excel')),
              PopupMenuItem(value: 'ventas_csv', child: Text('Ventas/Día CSV')),
            ],
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(productoControllerProvider.notifier).cargarProductos();
                await _cargarDatos();
              },
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rango de fechas', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _FechaPicker(label: 'Desde', notifier: _fechaInicio, onChanged: (_) => _cargarDatos())),
                              const SizedBox(width: 12),
                              Expanded(child: _FechaPicker(label: 'Hasta', notifier: _fechaFin, onChanged: (_) => _cargarDatos())),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _kpis(productosState),
                          const SizedBox(height: 8),
                          TabBar(
                            isScrollable: true,
                            labelColor: Colors.blue.shade800,
                            tabs: const [
                              Tab(text: 'Productos'),
                              Tab(text: 'Categorías'),
                              Tab(text: 'Pedidos'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Productos
                          ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              const Text('Top Productos (unidades)', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildTopProductosChart(),
                            ],
                          ),
                          // Categorías
                          ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              const Text('Participación por categoría', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildCategoriasPie(),
                            ],
                          ),
                          // Pedidos
                          ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              const Text('Pedidos por estado', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildPedidosDonut(),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loading || _exporting ? null : () => _generarPdf(productosState),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Reporte PDF'),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _btnExport('Prod Excel', 'productos_excel', productosState),
                                  _btnExport('Prod CSV', 'productos_csv', productosState),
                                  _btnExport('Ped Excel', 'pedidos_excel', productosState),
                                  _btnExport('Ped CSV', 'pedidos_csv', productosState),
                                  _btnExport('Ventas Excel', 'ventas_excel', productosState),
                                  _btnExport('Ventas CSV', 'ventas_csv', productosState),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _kpis(ProductoState state) {
    final totalProductos = state.productos.length;
    final lowStock = state.productosStockBajo.length;

    return Row(
      children: [
        Expanded(child: _kpi('Productos', '$totalProductos', Icons.inventory_2, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _kpi('Stock bajo', '$lowStock', Icons.warning, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _kpi('Ventas Mes', '\$${_ventasMes.toStringAsFixed(2)}', Icons.attach_money, Colors.green)),
      ],
    );
  }

  Widget _kpi(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductosChart() {
    if (_topProductos.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    final bars = <BarChartGroupData>[];
    for (var i = 0; i < _topProductos.length; i++) {
      final p = _topProductos[i];
      final unidades = (p['totalVendido'] as num?)?.toDouble() ?? 0;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: unidades, color: Colors.blue, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      );
    }

    return RepaintBoundary(
      key: _chartKey,
      child: Container(
        height: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: bars,
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= _topProductos.length) return const SizedBox.shrink();
                    // Calcular step ~ evitar solape (asumiendo ancho aprox.)
                    final step = ChartUtils.stepForLabels(itemCount: _topProductos.length, availableWidth: 240);
                    if (idx % step != 0) return const SizedBox.shrink();
                    final nombre = (_topProductos[idx]['nombre'] as String?) ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ChartUtils.rotatedLabel(nombre),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  

  Widget _buildCategoriasPie() {
    if (_ingresosPorCategoria.isEmpty) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

  final total = _ingresosPorCategoria.fold<double>(0, (s, e) => s + ((e['ingresos'] as num?)?.toDouble() ?? 0));
    final sections = <PieChartSectionData>[];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.indigo];
    for (var i = 0; i < _ingresosPorCategoria.length; i++) {
      final item = _ingresosPorCategoria[i];
      final value = (item['ingresos'] as num).toDouble();
      final percent = total == 0 ? 0 : (value / total) * 100;
      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: value,
        radius: 60,
        title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ));
    }

    return RepaintBoundary(
      key: _pieCatKey,
      child: Container(
      height: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Expanded(child: PieChart(PieChartData(sectionsSpace: 1, centerSpaceRadius: 0, sections: sections))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(_ingresosPorCategoria.length, (i) {
              final item = _ingresosPorCategoria[i];
              final color = colors[i % colors.length];
              final name = (item['categoria'] as String?) ?? '';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPedidosDonut() {
    if (_pedidosPorEstado.isEmpty) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    final total = _pedidosPorEstado.fold<int>(0, (s, e) => s + (e['cantidad'] as int));
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.indigo];
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < _pedidosPorEstado.length; i++) {
      final item = _pedidosPorEstado[i];
      final value = (item['cantidad'] as num).toDouble();
      final percent = total == 0 ? 0 : (value / total) * 100;
      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: value,
        radius: 60,
        title: percent >= 10 ? '${percent.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ));
    }

    return RepaintBoundary(
      key: _donutKey,
      child: Container(
      height: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40, // donut
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(_pedidosPorEstado.length, (i) {
              final item = _pedidosPorEstado[i];
              final color = colors[i % colors.length];
              final name = (item['estado'] as String?) ?? '';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _generarPdf(ProductoState productosState) async {
    try {
      // Capturar imágenes de las gráficas
      Future<Uint8List?> capture(GlobalKey key) async {
        final ro = key.currentContext?.findRenderObject();
        if (ro is RenderRepaintBoundary) {
          final image = await ro.toImage(pixelRatio: 3.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          return byteData?.buffer.asUint8List();
        }
        return null;
      }

      final chartPng = await capture(_chartKey);
      final chartCatPng = await capture(_pieCatKey);
      final chartEstadoPng = await capture(_donutKey);

      final data = ReportData(
        fechaInicio: _fechaInicio.value,
        fechaFin: _fechaFin.value,
        totalProductos: productosState.productos.length,
        productosStockBajo: productosState.productosStockBajo.length,
        ventasMesActual: _ventasMes,
        topProductos: _topProductos,
        ventasPorDia: _ventasPorDia,
        ingresosPorCategoria: _ingresosPorCategoria,
        pedidosPorEstado: _pedidosPorEstado,
        graficaPng: chartPng,
        graficaCategoriasPng: chartCatPng,
        graficaEstadosPng: chartEstadoPng,
      );

      await _reportService.shareReport(data: data, fileName: 'reporte_inventario.pdf');
      _showSnack('PDF generado');
    } catch (e) {
      _showSnack('No se pudo generar el PDF: $e');
    }
  }

  Widget _btnExport(String label, String action, ProductoState productosState) {
    return ElevatedButton(
      onPressed: _loading || _exporting ? null : () => _handleExport(action, productosState),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _handleExport(String action, ProductoState productosState) async {
    setState(() => _exporting = true);
    try {
      if (action.startsWith('productos')) {
        final productos = productosState.productos.map((p) => p.toJson()).toList();
        if (action.endsWith('excel')) {
          final file = await _reportService.exportarProductosExcel(productos);
          await _reportService.compartirArchivo(file, texto: 'Listado de productos');
        } else {
          final file = await _reportService.exportarProductosCsv(productos);
          await _reportService.compartirArchivo(file, texto: 'Listado de productos (CSV)');
        }
        _showSnack('Productos exportados');
      } else if (action.startsWith('pedidos')) {
        // Para simplicidad: reutilizar métricas de pedidos por estado para exportar resumen
        final pedidosResumen = _pedidosPorEstado.map((e) => {
              'estado': e['estado'],
              'cantidad': e['cantidad'],
            }).toList();
        if (action.endsWith('excel')) {
          final file = await _reportService.exportarPedidosExcel(pedidosResumen, nombre: 'pedidos_resumen.xlsx');
          await _reportService.compartirArchivo(file, texto: 'Resumen de pedidos por estado');
        } else {
          final file = await _reportService.exportarPedidosCsv(pedidosResumen, nombre: 'pedidos_resumen.csv');
          await _reportService.compartirArchivo(file, texto: 'Resumen de pedidos por estado (CSV)');
        }
        _showSnack('Pedidos exportados');
      } else if (action.startsWith('ventas')) {
        final ventas = _ventasPorDia.map((e) => {
              'fecha': e['fecha'],
              'total': e['total'],
            }).toList();
        if (action.endsWith('excel')) {
          final file = await _reportService.exportarVentasPorDiaExcel(ventas);
          await _reportService.compartirArchivo(file, texto: 'Ventas por día');
        } else {
          final file = await _reportService.exportarVentasPorDiaCsv(ventas);
          await _reportService.compartirArchivo(file, texto: 'Ventas por día (CSV)');
        }
        _showSnack('Ventas por día exportadas');
      }
    } catch (e) {
      _showSnack('Error exportando: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

class _FechaPicker extends StatefulWidget {
  final String label;
  final ValueNotifier<DateTime?> notifier;
  final ValueChanged<DateTime?>? onChanged;

  const _FechaPicker({required this.label, required this.notifier, this.onChanged});

  @override
  State<_FechaPicker> createState() => _FechaPickerState();
}

class _FechaPickerState extends State<_FechaPicker> {
  @override
  Widget build(BuildContext context) {
    final value = widget.notifier.value;
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 2),
          lastDate: DateTime(now.year + 2),
        );
        if (picked != null) {
          setState(() => widget.notifier.value = picked);
          widget.onChanged?.call(picked);
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value != null ? '${value.day}/${value.month}/${value.year}' : widget.label,
                style: TextStyle(color: value != null ? Colors.black : Colors.grey.shade600)),
            const Icon(Icons.date_range),
          ],
        ),
      ),
    );
  }
}
