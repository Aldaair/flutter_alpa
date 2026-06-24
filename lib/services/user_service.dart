// lib/services/user_service.dart
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserService {
  Future<bool> login(String codigoDni, String password) async {
    return await DatabaseHelper().loginOffline(codigoDni, password);
  }

  Future<String> fetchToken(String codigoDni, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json.encode({'codigo_dni': codigoDni, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return responseBody['token'] as String;
    }

    throw Exception('Error al obtener token de autenticación');
  }

  Future<Map<String, dynamic>> syncOfflineProfileSnapshot({
    required String dni,
    String? token,
    DatabaseHelper? databaseHelper,
  }) async {
    final dbHelper = databaseHelper ?? DatabaseHelper();
    await dbHelper.setCurrentUserDni(dni);

    final user = await dbHelper.getUserByDni(dni);
    if (user == null) {
      throw Exception('Usuario no encontrado en base de datos local');
    }

    return user;
  }
}
