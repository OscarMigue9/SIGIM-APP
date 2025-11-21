import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/integracion_entrega.dart';

class IntegracionService {
  final Uri _endpoint = Uri.parse(
    'http://18.218.21.107:8181/api/public/entregas',
  );

  Future<List<IntegracionEntrega>> obtenerEntregas() async {
    final response = await http.get(_endpoint);
    if (response.statusCode != 200) {
      throw Exception(
        'Error consultando integraci\u00f3n: ${response.statusCode}',
      );
    }

    try {
      final body = json.decode(response.body);
      if (body is List) {
        return body
            .map((e) => IntegracionEntrega.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Respuesta inesperada');
    } catch (e) {
      throw Exception('Error parseando integraci\u00f3n: $e');
    }
  }
}
