import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';

class ApiServiceUsuarioProcesos {
  Future<void> fetchAll(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/usuario-procesos'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar usuario-procesos. Codigo: ${response.statusCode}',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception(
        'La respuesta de usuario-procesos debe ser una lista JSON.',
      );
    }

    final db = await DatabaseHelper().sharedCatalogDatabase;
    final batch = db.batch();

    batch.delete('usuario_procesos');
    for (final row in decoded) {
      final item = row as Map;
      batch.insert('usuario_procesos', {
        'usuarios_id': item['usuario_id'],
        'proceso_id': item['proceso_id'],
      });
    }

    await batch.commit(noResult: true);
  }
}
