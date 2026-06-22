import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'dart:convert';

class OperacionesService {
  static const Map<String, String> _v2Endpoints = {
    'tal_largo': ApiConfig.operacionTalLargoEndpoint,
    'tal_horizontal': ApiConfig.operacionTalHorizontalEndpoint,
    'carguio': ApiConfig.operacionCarguioEndpoint,
    'empernador': ApiConfig.operacionEmpernadorEndpoint,
    'scalamin': ApiConfig.operacionScalaminEndpoint,
    'scissor': ApiConfig.operacionScissorEndpoint,
  };

  static const _legacyEndpoint = '/operaciones/crear';

  Future<bool> crear(String tipo, List<Map<String, dynamic>> dataList) async {
    try {
      final endpoint = _v2Endpoints[tipo];

      if (endpoint != null) {
        return _postV2(endpoint, tipo, dataList);
      }

      return _postLegacy(tipo, dataList);
    } catch (e) {
      print('❌ Error enviando $tipo: $e');
      return false;
    }
  }

  Future<bool> _postV2(
    String endpoint,
    String tipo,
    List<Map<String, dynamic>> dataList,
  ) async {
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
  }

  Future<bool> _postLegacy(
    String tipo,
    List<Map<String, dynamic>> dataList,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_legacyEndpoint');
    final body = jsonEncode({'tipo': tipo, 'data': dataList});

    print('📤 [legacy/$tipo] URL: $url');
    print('📤 BODY: ${body.length} chars');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('📥 STATUS: ${response.statusCode}');
    print('📥 RESPONSE: ${response.body}');

    return response.statusCode == 200;
  }
}
