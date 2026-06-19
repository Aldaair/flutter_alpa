import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/JefeGuardia.dart';

class ApiServiceJefeGuardia {
  ApiServiceJefeGuardia({HorizontalCatalogRepository? catalogRepository})
    : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  /// Obtener jefes de guardia desde la API y guardarlos localmente
  Future<List<JefeGuardia>> fetchJefesGuardia(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.jefe_guardias}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        List<JefeGuardia> jefes = responseData
            .map((data) => JefeGuardia.fromJson(data))
            .toList();

        await saveJefesToLocalDB(jefes);

        return jefes;
      } else {
        throw Exception(
          'Error al cargar jefes de guardia. Código: ${response.statusCode}',
        );
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  /// Guardar jefes en base de datos local
  Future<void> saveJefesToLocalDB(List<JefeGuardia> jefes) async {
    await _catalogRepository.refreshJefesGuardia(jefes);
  }
}
