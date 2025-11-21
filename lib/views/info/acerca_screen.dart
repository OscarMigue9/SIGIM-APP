import 'package:flutter/material.dart';

class AcercaScreen extends StatelessWidget {
  const AcercaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Inventario App', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Versión 1.0.0'),
          SizedBox(height: 12),
          Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Sistema de gestión de inventario y pedidos para distribuidora de muebles, con roles de admin, vendedor y cliente.'),
          SizedBox(height: 16),
          Text('Características principales:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('- CRUD de productos, stock y ajustes con historial.'),
          Text('- Flujo de pedidos con descuento de stock y estados.'),
          Text('- Reportes de pedidos/ventas y exportaciones básicas.'),
          Text('- Alertas visuales de stock bajo y pedidos pendientes.'),
          Text('- Tema claro/oscuro y control por roles.'),
          SizedBox(height: 16),
          Text('Créditos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Desarrollado como parte de SIGIM (Sistema de Gestión de Inventario de Muebles).'),
          SizedBox(height: 16),
          Text('Licencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Uso interno académico/demostrativo.'),
        ],
      ),
    );
  }
}
