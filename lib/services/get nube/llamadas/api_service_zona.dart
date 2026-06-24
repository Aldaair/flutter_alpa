import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/zona.dart';

class ApiServiceZona {
  ApiServiceZona({HorizontalCatalogRepository? catalogRepository})
    : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  Future<List<Zona>> fetchZonas(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.zonasEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! List) {
          throw Exception('La respuesta de zonas debe ser una lista JSON.');
        }

        final zonas = decoded
            .whereType<Map>()
            .map(
              (data) => Zona.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        await saveZonasToLocalDB(zonas);

        return zonas;
      }

      throw Exception(
        'Error al cargar las zonas. Codigo: ${response.statusCode}',
      );
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  Future<void> saveZonasToLocalDB(List<Zona> zonas) async {
    await _catalogRepository.refreshZonas(zonas);
  }
}
