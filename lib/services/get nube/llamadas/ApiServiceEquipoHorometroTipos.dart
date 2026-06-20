import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/EquipoHorometroTipo.dart';

class ApiServiceEquipoHorometroTipos {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<EquipoHorometroTipo>> fetchEquipoHorometroTipos(
      String token) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.equipoHorometroTiposEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        List<EquipoHorometroTipo> items = [];

        for (var equipo in responseData) {
          final equipoId = equipo['equipo_id'];
          final equipoNombre = equipo['equipo_nombre'];
          final horometroTipos = equipo['horometro_tipos'] as List<dynamic>;

          for (var tipo in horometroTipos) {
            items.add(EquipoHorometroTipo(
              equipoId: equipoId,
              equipoNombre: equipoNombre,
              tipoHorometroId: tipo['id'],
              tipoHorometroNombre: tipo['nombre'],
            ));
          }
        }

        await _dbHelper.deleteAll('equipo_horometro_tipos');
        await saveToLocalDB(items);

        return items;
      } else {
        throw Exception(
            'Error al cargar equipo-horómetro tipos. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  Future<void> saveToLocalDB(List<EquipoHorometroTipo> items) async {
    for (var item in items) {
      await _dbHelper.insert('equipo_horometro_tipos', item.toMap());
    }
  }
}
