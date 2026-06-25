import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/plan_avance_th.dart';

class ApiServicePlanAvance {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<PlanAvanceTH>> fetchPlanesAvance(
    String token,
    int periodoId,
  ) async {
    try {
      final endpoint =
          '${ApiConfig.baseUrl}${ApiConfig.planAvanceTHEndpoint}por-periodo/$periodoId';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📥 PlanAvanceTH status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final planes = responseData
            .whereType<Map>()
            .map(
              (data) => PlanAvanceTH.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        print('📦 PlanAvanceTH rows recibidas: ${planes.length}');

        await _dbHelper.deleteAll('planes_metrajes_avances');
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

  Future<void> savePlanesToLocalDB(List<PlanAvanceTH> planes) async {
    final sharedDb = await _dbHelper.sharedCatalogDatabase;
    print('🗄️ PlanAvanceTH shared DB path: ${sharedDb.path}');

    for (final plan in planes) {
      await _dbHelper.insert('planes_metrajes_avances', plan.toMap());
    }

    print('✅ PlanAvanceTH rows guardadas: ${planes.length}');
  }
}
