import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/EstadostBD.dart';

class ApiServiceEstado {
  ApiServiceEstado({HorizontalCatalogRepository? catalogRepository})
    : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  Future<List<EstadostBD>> fetchEstados(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.estadosEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        List<EstadostBD> estados = responseData
            .map((data) => EstadostBD.fromJson(data))
            .toList();

        await _catalogRepository.refreshEstados(estados);

        return estados;
      } else {
        throw Exception(
          'Error al cargar los estados. Código: ${response.statusCode}',
        );
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }
}
