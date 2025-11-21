import 'package:flutter/material.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Cómo usar la app', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('• Admin: crea usuarios/roles, gestiona productos, ajustes de inventario y reportes.'),
          Text('• Vendedor: crea pedidos, actualiza estados, consulta stock, puede crear clientes rápidos.'),
          Text('• Cliente: ve sus pedidos y estado.'),
          SizedBox(height: 12),
          Text('Módulos principales:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('• Inventario: CRUD de productos, stock y ajustes con histórico.'),
          Text('• Pedidos: crea, descuenta stock automático, cambia estado y guarda historial.'),
          Text('• Reportes: métricas de ventas/pedidos, exportación básica (CSV/PDF según dispositivo).'),
          Text('• Alertas: badges de stock bajo y pedidos pendientes.'),
          SizedBox(height: 20),
          Text('Consejos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('• Mantén productos y stock al día para evitar errores en pedidos.'),
          Text('• Usa estados de pedido para llevar trazabilidad.'),
          Text('• Exporta reportes periódicamente para respaldo.'),
          SizedBox(height: 20),
          Text('Soporte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Para soporte, contacta al administrador del sistema.'),
        ],
      ),
    );
  }
}
