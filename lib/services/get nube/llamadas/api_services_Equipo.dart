import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/Equipo.dart';

class ApiServiceEquipo {
  ApiServiceEquipo({HorizontalCatalogRepository? catalogRepository})
    : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  /// Obtener equipos desde la API y guardarlos localmente
  Future<List<Equipo>> fetchEquipos(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.equipoEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        List<Equipo> equipos = responseData
            .map((data) => Equipo.fromJson(data))
            .toList();

        await saveEquiposToLocalDB(equipos);

        return equipos;
      } else {
        throw Exception(
          'Error al cargar los equipos. Código: ${response.statusCode}',
        );
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  /// Guardar equipos en base de datos local
  Future<void> saveEquiposToLocalDB(List<Equipo> equipos) async {
    await _catalogRepository.refreshEquipos(equipos);
  }
}
