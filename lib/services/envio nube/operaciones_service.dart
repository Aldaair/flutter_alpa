import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'dart:convert';

class OperacionesService {

  // ✅ CREAR (uno o varios)
  Future<bool> crear(String tipo, dynamic data) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/operaciones/crear');

    final body = jsonEncode({
      "tipo": tipo,
      "data": data
    });

    print("📤 URL: $url");
    print("📤 BODY: $body");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print("📥 STATUS: ${response.statusCode}");
    print("📥 RESPONSE: ${response.body}");

    return response.statusCode == 200;

  } catch (e) {
    print('❌ Error crear: $e');
    return false;
  }
}

  // ✅ GET (con filtros)
  Future<List<dynamic>> obtener(String tipo,
      {String? estado, int limit = 50, int offset = 0}) async {

    try {
      String url =
          '${ApiConfig.baseUrl}/operaciones/$tipo?limit=$limit&offset=$offset';

      if (estado != null) {
        url += '&estado=$estado';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['data'];
      } else {
        return [];
      }

    } catch (e) {
      print('Error obtener: $e');
      return [];
    }
  }

  // ✅ UPDATE (uno o varios)
  Future<bool> actualizar(String tipo, dynamic data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/operaciones/actualizar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "tipo": tipo,
          "data": data
        }),
      );

      return response.statusCode == 200;

    } catch (e) {
      print('Error actualizar: $e');
      return false;
    }
  }
}