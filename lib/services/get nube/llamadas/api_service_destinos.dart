import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/destino.dart';

class ApiServiceDestinos {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Destino>> fetchDestinos(String token) async {
    try {
      final endpoint = '${ApiConfig.baseUrl}${ApiConfig.origenDestinoEndpoint}';
      print('📡 OrigenDestino endpoint: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📥 OrigenDestino status: ${response.statusCode}');

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

        print('📦 OrigenDestino rows recibidas: ${destinos.length}');

        await _dbHelper.deleteAll('origen_destino');
        await saveToLocalDB(destinos);

        return destinos;
      }

      throw Exception(
        'Error al cargar origen_destino. Código: ${response.statusCode}',
      );
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  Future<void> saveToLocalDB(List<Destino> destinos) async {
    final sharedDb = await _dbHelper.sharedCatalogDatabase;
    print('🗄️ OrigenDestino shared DB path: ${sharedDb.path}');

    for (final destino in destinos) {
      await _dbHelper.insert('origen_destino', destino.toMap());
    }

    print('✅ OrigenDestino rows guardadas: ${destinos.length}');
  }
}
