import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'dart:convert';

class OperacionesService {
  static const Map<String, String> _endpoints = {
    'tal_largo': ApiConfig.operacionTalLargoEndpoint,
    'tal_horizontal': ApiConfig.operacionTalHorizontalEndpoint,
    'carguio': ApiConfig.operacionCarguioEndpoint,
    'empernador': ApiConfig.operacionEmpernadorEndpoint,
    'scalamin': ApiConfig.operacionScalaminEndpoint,
    'scissor': ApiConfig.operacionScissorEndpoint,
  };

  Future<bool> crear(String tipo, List<Map<String, dynamic>> dataList) async {
    try {
      final endpoint = _endpoints[tipo];
      if (endpoint == null) {
        print('❌ Tipo de operación desconocido: $tipo');
        return false;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final body = jsonEncode(dataList);

      print('📤 [$tipo] URL: $url');
      print('📤 BODY: ${body.length} chars');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('📥 STATUS: ${response.statusCode}');
      print('📥 RESPONSE: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error enviando $tipo: $e');
      return false;
    }
  }
}
