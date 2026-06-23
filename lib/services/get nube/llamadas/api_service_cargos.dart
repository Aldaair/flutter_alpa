import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/cargo.dart';

class ApiServiceCargos {
  ApiServiceCargos({HorizontalCatalogRepository? catalogRepository})
    : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  Future<List<Cargo>> fetchCargos(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cargosEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! List) {
          throw Exception('La respuesta de cargos debe ser una lista JSON.');
        }

        final cargos = decoded
            .whereType<Map>()
            .map(
              (data) => Cargo.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        await _catalogRepository.refreshCargos(cargos);
        return cargos;
      }

      throw Exception('Error al cargar cargos. Codigo: ${response.statusCode}');
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }
}
