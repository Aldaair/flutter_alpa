import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/DimTurno.dart';

class ApiServiceDimTurnos {
  ApiServiceDimTurnos({HorizontalCatalogRepository? catalogRepository})
    : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  Future<List<DimTurno>> fetchDimTurnos(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.turnosEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! List) {
          throw Exception('La respuesta de turnos debe ser una lista JSON.');
        }

        final turnos = decoded
            .whereType<Map>()
            .map(
              (data) => DimTurno.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        await _catalogRepository.refreshDimTurnos(turnos);
        return turnos;
      }

      throw Exception(
        'Error al cargar turnos. Codigo: ${response.statusCode}',
      );
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }
}
