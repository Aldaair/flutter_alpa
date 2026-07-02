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
    batch.delete('usuario_procesos');

    for (final row in decoded) {
      final item = row as Map;
      final operadorId = item['id'];

      batch.insert('usuario_directorio', {
        'codigo_dni': item['codigo_dni']?.toString() ?? '',
        'id': operadorId,
        'nombres': item['nombres'] ?? '',
        'apellidos': item['apellidos'] ?? '',
        'rol': item['rol'],
        'cargo_id': item['cargo_id'],
        'password': item['password'],
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (operadorId != null) {
        final procesos = item['procesos'] as List? ?? [];
        for (final p in procesos) {
          batch.insert('usuario_procesos', {
            'usuarios_id': operadorId,
            'proceso_id': (p as Map)['id'],
          });
        }
      }
    }

    await batch.commit(noResult: true);
  }
}
