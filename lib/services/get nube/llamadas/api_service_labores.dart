import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/DimLabor.dart';

class ApiServiceLabores {
  ApiServiceLabores({HorizontalCatalogRepository? catalogRepository})
    : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  Future<List<DimLabor>> fetchLabores(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.laboresEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! List) {
          throw Exception('La respuesta de labores debe ser una lista JSON.');
        }

        final labores = decoded
            .whereType<Map>()
            .map(
              (data) => DimLabor.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        await _catalogRepository.refreshLabores(labores);
        return labores;
      }

      throw Exception(
        'Error al cargar labores. Codigo: ${response.statusCode}',
      );
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }
}
