import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';

class ApiServiceUsuarioDirectorio {
  Future<void> fetchAll(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioDirectorioEndpoint}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar usuarios. Codigo: ${response.statusCode}',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('La respuesta de usuarios debe ser una lista JSON.');
    }

    final db = await DatabaseHelper().sharedCatalogDatabase;
    final batch = db.batch();

    batch.delete('usuario_directorio');
    for (final row in decoded) {
      final item = row as Map;
      batch.insert('usuario_directorio', {
        'codigo_dni': item['codigo_dni']?.toString() ?? '',
        'operador_id': item['operador_id'],
        'nombres': item['nombres'] ?? '',
        'apellidos': item['apellidos'] ?? '',
        'rol': item['rol'],
        'cargo_id': item['cargo_id'],
        'password': item['password'],
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }
}
