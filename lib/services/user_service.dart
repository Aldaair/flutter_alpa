// lib/services/user_service.dart
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/services/api_service.dart';
import 'dart:convert';


class UserService {
  final ApiService _apiService = ApiService();
  final String baseUrl = ApiConfig.baseUrl;
  Future<String> login(String codigoDni, String password) async {
    return await _apiService.login(codigoDni, password);  // Ahora retorna el token
  }


   Future<Map<String, dynamic>> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/perfil'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener el perfil del usuario');
    }
  }
}
