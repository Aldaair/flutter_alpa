import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/tipo_horometro.dart';

class ApiServiceTipoHorometro {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<TipoHorometro>> fetchTiposHorometro(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tipoHorometroEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        List<TipoHorometro> tipos = responseData
            .map((data) => TipoHorometro.fromJson(data))
            .toList();

        await _dbHelper.deleteAll('tipo_horometro');
        await saveTiposToLocalDB(tipos);

        return tipos;
      } else {
        throw Exception(
          'Error al cargar tipos de horómetro. Código: ${response.statusCode}',
        );
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  Future<void> saveTiposToLocalDB(List<TipoHorometro> tipos) async {
    for (var tipo in tipos) {
      Map<String, dynamic> tipoData = tipo.toMap();
      await _dbHelper.insert('tipo_horometro', tipoData);
    }
  }
}
