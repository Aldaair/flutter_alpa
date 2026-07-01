import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/models/categoria_estado.dart';

class ApiServiceCategoriaEstado {
  ApiServiceCategoriaEstado({HorizontalCatalogRepository? catalogRepository})
    : _catalogRepository = catalogRepository ?? HorizontalCatalogRepository();

  final HorizontalCatalogRepository _catalogRepository;

  Future<List<CategoriaEstado>> fetchCategoriasEstados(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categoriasEstadosEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final categorias = responseData
            .map((d) => CategoriaEstado.fromJson(d))
            .toList();
        await _catalogRepository.refreshCategoriasEstados(categorias);
        return categorias;
      } else {
        throw Exception(
          'Error al cargar categorías de estados. Código: ${response.statusCode}',
        );
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }
}
