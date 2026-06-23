import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';

class ApiServiceUsuarioEquipos {
  Future<void> fetchAll(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioEquiposEndpoint}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar equipos por usuario. Codigo: ${response.statusCode}',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception(
        'La respuesta de equipos por usuario debe ser una lista JSON.',
      );
    }

    final db = await DatabaseHelper().sharedCatalogDatabase;
    final batch = db.batch();

    batch.delete('usuario_equipos');
    for (final row in decoded) {
      final item = row as Map;
      batch.insert('usuario_equipos', {
        'usuarios_id': item['usuarios_id'],
        'proceso_id': item['proceso_id'],
        'equipo_id': item['equipo_id'],
      });
    }

    await batch.commit(noResult: true);
  }
}
