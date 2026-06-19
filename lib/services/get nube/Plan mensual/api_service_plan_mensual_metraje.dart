import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/PlanMetrajeTL.dart';

class ApiServicePlanMetraje {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<PlanMetrajeTL>> fetchPlanesMetraje(
    String token,
    int periodoId,
  ) async {
    try {
      final endpoint =
          '${ApiConfig.baseUrl}${ApiConfig.planMetrajeTLEndpoint}por-periodo/$periodoId';
      print('📡 PlanMetrajeTL endpoint: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📥 PlanMetrajeTL status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final planes = responseData
            .whereType<Map>()
            .map(
              (data) => PlanMetrajeTL.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        print('📦 PlanMetrajeTL rows recibidas: ${planes.length}');

        await _dbHelper.deleteAll('PlanMetrajeTL');
        await savePlanesToLocalDB(planes);

        return planes;
      } else {
        throw Exception(
          'Error al obtener los planes de metraje. Código: ${response.statusCode}',
        );
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  Future<void> savePlanesToLocalDB(List<PlanMetrajeTL> planes) async {
    final sharedDb = await _dbHelper.sharedCatalogDatabase;
    print('🗄️ PlanMetrajeTL shared DB path: ${sharedDb.path}');

    for (final plan in planes) {
      await _dbHelper.insert('PlanMetrajeTL', plan.toMap());
    }

    print('✅ PlanMetrajeTL rows guardadas: ${planes.length}');
  }
}
