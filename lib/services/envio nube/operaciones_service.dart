import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'dart:convert';

class OperationSendItemResult {
  const OperationSendItemResult({
    required this.localIndex,
    required this.success,
    required this.statusCode,
    required this.responseBody,
  });

  final int localIndex;
  final bool success;
  final int? statusCode;
  final String responseBody;
}

class OperationSendBatchResult {
  const OperationSendBatchResult({
    required this.tipo,
    required this.totalItems,
    required this.items,
    this.error,
  });

  final String tipo;
  final int totalItems;
  final List<OperationSendItemResult> items;
  final Object? error;

  bool get isSuccess =>
      totalItems > 0 &&
      error == null &&
      items.length == totalItems &&
      items.every((item) => item.success);

  int get attemptedCount => items.length;
  int get successCount => items.where((item) => item.success).length;
  int get failureCount => items.where((item) => !item.success).length;
  int get skippedCount => totalItems - attemptedCount;
}

class OperacionesService {
  OperacionesService({http.Client? client}) : _client = client ?? http.Client();

  static const Map<String, String> _v2Endpoints = {
    'tal_largo': ApiConfig.operacionTalLargoEndpoint,
    'tal_horizontal': ApiConfig.operacionTalHorizontalEndpoint,
    'carguio': ApiConfig.operacionCarguioEndpoint,
    'acarreo': ApiConfig.operacionAcarreoEndpoint,
    'empernador': ApiConfig.operacionEmpernadorEndpoint,
    'scalamin': ApiConfig.operacionScalaminEndpoint,
    'scissor': ApiConfig.operacionScissorEndpoint,
  };

  final http.Client _client;

  Future<OperationSendBatchResult> crear(
    String tipo,
    List<Map<String, dynamic>> dataList, {
    Future<void> Function(OperationSendItemResult result)? onItemProcessed,
  }) async {
    final results = <OperationSendItemResult>[];

    try {
      final endpoint = _v2Endpoints[tipo];
      if (endpoint == null) {
        print('❌ Tipo de operación desconocido: $tipo');
        return OperationSendBatchResult(
          tipo: tipo,
          totalItems: dataList.length,
          items: results,
          error: ArgumentError('Unknown operation type: $tipo'),
        );
      }

      if (dataList.isEmpty) {
        print('⚠️ [$tipo] No hay operaciones para enviar');
        return OperationSendBatchResult(
          tipo: tipo,
          totalItems: 0,
          items: results,
        );
      }

      for (var i = 0; i < dataList.length; i++) {
        final result = await _postV2(endpoint, tipo, dataList[i], i + 1, i);
        results.add(result);

        if (onItemProcessed != null) {
          await onItemProcessed(result);
        }

        if (!result.success) {
          break;
        }
      }

      return OperationSendBatchResult(
        tipo: tipo,
        totalItems: dataList.length,
        items: results,
      );
    } catch (e) {
      print('❌ Error enviando $tipo: $e');
      return OperationSendBatchResult(
        tipo: tipo,
        totalItems: dataList.length,
        items: results,
        error: e,
      );
    }
  }

  Future<OperationSendItemResult> _postV2(
    String endpoint,
    String tipo,
    Map<String, dynamic> request,
    int index,
    int localIndex,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final body = jsonEncode(request);

    print('📤 [$tipo][$index] URL: $url');
    print('📤 BODY: ${body.length} chars');
    print('📤 BODY CONTENT: $body');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('📥 STATUS: ${response.statusCode}');
      print('📥 RESPONSE: ${response.body}');

      return OperationSendItemResult(
        localIndex: localIndex,
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } catch (e) {
      print('❌ [$tipo][$index] Request error: $e');
      return OperationSendItemResult(
        localIndex: localIndex,
        success: false,
        statusCode: null,
        responseBody: e.toString(),
      );
    }
  }
}
