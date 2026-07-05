import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:i_miner/config/api/api_config.dart';

class ApiService {
  static String? _macOsSessionToken;
  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  bool get _usesInMemoryTokenStore =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> saveToken(String token) async {
    if (_usesInMemoryTokenStore) {
      _macOsSessionToken = token;
      return;
    }
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    if (_usesInMemoryTokenStore) {
      return _macOsSessionToken;
    }
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<void> clearToken() async {
    if (_usesInMemoryTokenStore) {
      _macOsSessionToken = null;
      return;
    }
    await _secureStorage.delete(key: 'auth_token');
  }

  Future<String> login(String codigoDni, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json.encode({'codigo_dni': codigoDni, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      print("📥 LOGIN RESPONSE: $responseBody");
      final token = responseBody['token'];
      await saveToken(token);
      return token;
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

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
