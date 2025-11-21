import 'dart:typed_data';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/report_data.dart';

class ReportService {
  Future<Uint8List> generateReportPdf(ReportData data) async {
  final pdf = pw.Document();


  final dateFormat = DateFormat('dd/MM/yyyy');
  final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

    final periodo = () {
      if (data.fechaInicio == null && data.fechaFin == null) return 'Todos';
      final ini = data.fechaInicio != null ? dateFormat.format(data.fechaInicio!) : '...';
      final fin = data.fechaFin != null ? dateFormat.format(data.fechaFin!) : '...';
      return '$ini - $fin';
    }();

    // Tabla de KPIs
    pw.Widget kpiCell(String title, String value) => pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );

  final topProductsTable = pw.TableHelper.fromTextArray(
      headers: const ['Producto', 'Unidades', 'Ingresos aprox.'],
      data: data.topProductos.map((p) {
        final nombre = p['nombre']?.toString() ?? '-';
        final unidades = (p['totalVendido'] as num?)?.toInt() ?? 0;
        final precio = (p['precio'] as num?)?.toDouble() ?? 0.0;
        final ingresos = precio * unidades;
        return [
          nombre,
          unidades.toString(),
          currency.format(ingresos),
        ];
      }).toList(),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.2),
      },
    );

    // Tablas adicionales
    final ventasDiaTable = data.ventasPorDia.isEmpty
        ? null
        : pw.TableHelper.fromTextArray(
            headers: const ['Fecha', 'Total'],
            data: data.ventasPorDia.map((e) {
              final d = e['fecha'] as DateTime;
              final total = (e['total'] as num).toDouble();
              return [dateFormat.format(d), currency.format(total)];
            }).toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
          );

    final categoriasTable = data.ingresosPorCategoria.isEmpty
        ? null
        : pw.TableHelper.fromTextArray(
            headers: const ['Categoría', 'Ingresos'],
            data: data.ingresosPorCategoria.map((e) {
              return [e['categoria']?.toString() ?? '-', currency.format((e['ingresos'] as num).toDouble())];
            }).toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
          );

    final estadosTable = data.pedidosPorEstado.isEmpty
        ? null
        : pw.TableHelper.fromTextArray(
            headers: const ['Estado', 'Cantidad'],
            data: data.pedidosPorEstado.map((e) {
              return [e['estado']?.toString() ?? '-', (e['cantidad'] as int).toString()];
            }).toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
          );

    // Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        ),
        header: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Inventario App', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
      pw.Text('Reporte de Inventario y Ventas',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Periodo: $periodo', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),

          // KPIs
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: kpiCell('Productos totales', data.totalProductos.toString())),
              pw.SizedBox(width: 8),
              pw.Expanded(child: kpiCell('Productos con stock bajo', data.productosStockBajo.toString())),
              pw.SizedBox(width: 8),
              pw.Expanded(child: kpiCell('Ventas del mes', currency.format(data.ventasMesActual))),
            ],
          ),

          pw.SizedBox(height: 18),
      pw.Text('Productos mas vendidos',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          topProductsTable,

          if (data.graficaPng != null) ...[
            pw.SizedBox(height: 18),
      pw.Text('Grafica de Top Productos',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Image(pw.MemoryImage(data.graficaPng!), width: 400),
            ),
          ],

          // Ventas por día
          if (ventasDiaTable != null || data.graficaVentasDiaPng != null) ...[
            pw.SizedBox(height: 18),
            pw.Text('Ventas por dia', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            if (data.graficaVentasDiaPng != null) ...[
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Image(pw.MemoryImage(data.graficaVentasDiaPng!), width: 420)),
            ],
            if (ventasDiaTable != null) ...[
              pw.SizedBox(height: 8),
              ventasDiaTable,
            ],
          ],

          // Ingresos por categoría
          if (categoriasTable != null || data.graficaCategoriasPng != null) ...[
            pw.SizedBox(height: 18),
            pw.Text('Ingresos por categoria', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            if (data.graficaCategoriasPng != null) ...[
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Image(pw.MemoryImage(data.graficaCategoriasPng!), width: 380)),
            ],
            if (categoriasTable != null) ...[
              pw.SizedBox(height: 8),
              categoriasTable,
            ],
          ],

          // Pedidos por estado
          if (estadosTable != null || data.graficaEstadosPng != null) ...[
            pw.SizedBox(height: 18),
            pw.Text('Pedidos por estado', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            if (data.graficaEstadosPng != null) ...[
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Image(pw.MemoryImage(data.graficaEstadosPng!), width: 380)),
            ],
            if (estadosTable != null) ...[
              pw.SizedBox(height: 8),
              estadosTable,
            ],
          ],
        ],
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
      child: pw.Text('Pagina ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> shareReport({required ReportData data, String fileName = 'reporte.pdf'}) async {
    final bytes = await generateReportPdf(data);
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  // ------------------------------
  // Exportación Excel / CSV
  // ------------------------------

  Future<File> _crearArchivoTemporal(String nombre) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$nombre');
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    return file;
  }

  // Productos a Excel
  Future<File> exportarProductosExcel(List<Map<String, dynamic>> productos, {String nombre = 'productos.xlsx'}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Productos'];
    sheet.appendRow(['ID', 'Nombre', 'SKU', 'Categoría', 'Stock', 'Precio']);
    for (final p in productos) {
      sheet.appendRow([
        p['id_producto'],
        p['nombre'],
        p['sku'],
        p['categoria'],
        p['stock'],
        p['precio'],
      ]);
    }
    final bytes = excel.encode()!;
    final file = await _crearArchivoTemporal(nombre);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // Pedidos a Excel (resumen)
  Future<File> exportarPedidosExcel(List<Map<String, dynamic>> pedidos, {String nombre = 'pedidos.xlsx'}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Pedidos'];
    sheet.appendRow(['ID', 'Cliente', 'Estado', 'Total', 'Fecha']);
    for (final p in pedidos) {
      sheet.appendRow([
        p['id_pedido'],
        p['nombre_cliente'] ?? p['cliente'] ?? '',
        p['nombre_estado'] ?? p['estado'] ?? '',
        p['total'],
        p['fecha_creacion'],
      ]);
    }
    final bytes = excel.encode()!;
    final file = await _crearArchivoTemporal(nombre);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // Ventas por día a Excel
  Future<File> exportarVentasPorDiaExcel(List<Map<String, dynamic>> ventas, {String nombre = 'ventas_por_dia.xlsx'}) async {
    final excel = Excel.createExcel();
    final sheet = excel['VentasDia'];
    sheet.appendRow(['Fecha', 'Total']);
    for (final v in ventas) {
      sheet.appendRow([
        (v['fecha'] is DateTime) ? (v['fecha'] as DateTime).toIso8601String() : v['fecha'],
        v['total'],
      ]);
    }
    final bytes = excel.encode()!;
    final file = await _crearArchivoTemporal(nombre);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // CSV genérico
  String _toCsv(List<List<dynamic>> rows) {
    final buffer = StringBuffer();
    for (final r in rows) {
      buffer.writeln(r.map((e) {
        if (e == null) return '';
        final s = e.toString();
        if (s.contains(',') || s.contains('"')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }).join(','));
    }
    return buffer.toString();
  }

  Future<File> exportarProductosCsv(List<Map<String, dynamic>> productos, {String nombre = 'productos.csv'}) async {
    final rows = <List<dynamic>>[];
    rows.add(['ID', 'Nombre', 'SKU', 'Categoría', 'Stock', 'Precio']);
    for (final p in productos) {
      rows.add([
        p['id_producto'],
        p['nombre'],
        p['sku'],
        p['categoria'],
        p['stock'],
        p['precio'],
      ]);
    }
    final csv = _toCsv(rows);
    final file = await _crearArchivoTemporal(nombre);
    await file.writeAsString(csv, flush: true);
    return file;
  }

  Future<File> exportarPedidosCsv(List<Map<String, dynamic>> pedidos, {String nombre = 'pedidos.csv'}) async {
    final rows = <List<dynamic>>[];
    rows.add(['ID', 'Cliente', 'Estado', 'Total', 'Fecha']);
    for (final p in pedidos) {
      rows.add([
        p['id_pedido'],
        p['nombre_cliente'] ?? p['cliente'] ?? '',
        p['nombre_estado'] ?? p['estado'] ?? '',
        p['total'],
        p['fecha_creacion'],
      ]);
    }
    final csv = _toCsv(rows);
    final file = await _crearArchivoTemporal(nombre);
    await file.writeAsString(csv, flush: true);
    return file;
  }

  Future<File> exportarVentasPorDiaCsv(List<Map<String, dynamic>> ventas, {String nombre = 'ventas_por_dia.csv'}) async {
    final rows = <List<dynamic>>[];
    rows.add(['Fecha', 'Total']);
    for (final v in ventas) {
      rows.add([
        (v['fecha'] is DateTime) ? (v['fecha'] as DateTime).toIso8601String() : v['fecha'],
        v['total'],
      ]);
    }
    final csv = _toCsv(rows);
    final file = await _crearArchivoTemporal(nombre);
    await file.writeAsString(csv, flush: true);
    return file;
  }

  // Compartir archivos ya creados
  Future<void> compartirArchivo(File file, {String? texto}) async {
    await Share.shareXFiles([XFile(file.path)], text: texto);
  }
}
