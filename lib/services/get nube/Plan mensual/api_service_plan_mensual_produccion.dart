import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/plan_produccion.dart';

class ApiServicePlanProduccion {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<PlanProduccion>> fetchPlanesProduccion(
    String token,
    int periodoId,
  ) async {
    try {
      final endpoint =
          '${ApiConfig.baseUrl}${ApiConfig.planProduccionEndpoint}por-periodo/$periodoId';
      print('📡 PlanProduccion endpoint: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📥 PlanProduccion status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final planes = responseData
            .whereType<Map>()
            .map(
              (data) => PlanProduccion.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        print('📦 PlanProduccion rows recibidas: ${planes.length}');

        await _dbHelper.deleteAll('planes_produccion');
        await savePlanesToLocalDB(planes);

        return planes;
      } else {
        throw Exception(
          'Error al obtener los planes de producción. Código: ${response.statusCode}',
        );
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  Future<void> savePlanesToLocalDB(List<PlanProduccion> planes) async {
    final sharedDb = await _dbHelper.sharedCatalogDatabase;
    print('🗄️ PlanProduccion shared DB path: ${sharedDb.path}');

    for (final plan in planes) {
      await _dbHelper.insert('planes_produccion', plan.toMap());
    }

    print('✅ PlanProduccion rows guardadas: ${planes.length}');
  }
}
