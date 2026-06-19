import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/DimNivel.dart';

class ApiServiceNiveles {
  ApiServiceNiveles({HorizontalCatalogRepository? catalogRepository})
    : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  Future<List<DimNivel>> fetchNiveles(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.nivelesEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! List) {
          throw Exception('La respuesta de niveles debe ser una lista JSON.');
        }

        final niveles = decoded
            .whereType<Map>()
            .map(
              (data) => DimNivel.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        await _catalogRepository.refreshNiveles(niveles);
        return niveles;
      }

      throw Exception(
        'Error al cargar niveles. Codigo: ${response.statusCode}',
      );
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }
}
