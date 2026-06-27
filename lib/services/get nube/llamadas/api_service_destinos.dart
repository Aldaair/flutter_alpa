import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/destino.dart';

class ApiServiceDestinos {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Destino>> fetchDestinos(String token) async {
    try {
      final endpoint = '${ApiConfig.baseUrl}${ApiConfig.destinosEndpoint}';
      print('📡 Destinos endpoint: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📥 Destinos status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final destinos = responseData
            .whereType<Map>()
            .map(
              (data) => Destino.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        print('📦 Destinos rows recibidas: ${destinos.length}');

        await _dbHelper.deleteAll('destinos');
        await saveToLocalDB(destinos);

        return destinos;
      }

      throw Exception(
        'Error al cargar destinos. Código: ${response.statusCode}',
      );
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  Future<void> saveToLocalDB(List<Destino> destinos) async {
    final sharedDb = await _dbHelper.sharedCatalogDatabase;
    print('🗄️ Destinos shared DB path: ${sharedDb.path}');

    for (final destino in destinos) {
      await _dbHelper.insert('destinos', destino.toMap());
    }

    print('✅ Destinos rows guardadas: ${destinos.length}');
  }
}
