
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:i_miner/config/api/api_config.dart';

class ApiService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(); // Instancia de almacenamiento seguro

  // Realiza una petición POST para iniciar sesión
  Future<String> login(String codigoDni, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'codigo_dni': codigoDni,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      // Aquí extraemos el token de la respuesta
      final responseBody = json.decode(response.body);
      final token = responseBody['token']; // Asumiendo que el token está bajo la clave 'token'

      // Guardamos el token en almacenamiento seguro
      await _secureStorage.write(key: 'auth_token', value: token);

      return token;
    } else {
      throw Exception('Failed to login');
    }
  }

  // Recupera el token almacenado
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // Elimina el token almacenado (logout)
  Future<void> logout() async {
    await _secureStorage.delete(key: 'auth_token');
  }


   // Nuevo método POST genérico
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
  }

  // Método GET genérico (opcional, por si lo necesitas)
  Future<http.Response> get(String endpoint) async {
    final token = await getToken();
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
  
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    return await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
  }
}
