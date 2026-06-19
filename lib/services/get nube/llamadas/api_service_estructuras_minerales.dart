import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/DimEstructuraMineral.dart';

class ApiServiceEstructurasMinerales {
  ApiServiceEstructurasMinerales({
    HorizontalCatalogRepository? catalogRepository,
  }) : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  Future<List<DimEstructuraMineral>> fetchEstructurasMinerales(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.estructurasMineralesEndpoint}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! List) {
          throw Exception(
            'La respuesta de estructuras minerales debe ser una lista JSON.',
          );
        }

        final estructuras = decoded
            .whereType<Map>()
            .map(
              (data) => DimEstructuraMineral.fromJson(
                data.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();

        await _catalogRepository.refreshEstructurasMinerales(estructuras);
        return estructuras;
      }

      throw Exception(
        'Error al cargar estructuras minerales. Codigo: ${response.statusCode}',
      );
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }
}
