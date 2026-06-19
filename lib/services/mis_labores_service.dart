import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/offline_authorization_repository.dart';
import 'package:i_miner/models/assigned_labor.dart';
import 'package:i_miner/services/api_service.dart';

class MisLaboresService {
  MisLaboresService({
    ApiService? apiService,
    DatabaseHelper? databaseHelper,
    OfflineAuthorizationRepository? authorizationRepository,
    http.Client? client,
    String? baseUrl,
  }) : _apiService = apiService ?? ApiService(),
       _databaseHelper = databaseHelper ?? DatabaseHelper(),
       _authorizationRepository =
           authorizationRepository ?? OfflineAuthorizationRepository(),
       _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final ApiService _apiService;
  final DatabaseHelper _databaseHelper;
  final OfflineAuthorizationRepository _authorizationRepository;
  final http.Client _client;
  final String _baseUrl;

  Future<List<AssignedLabor>> fetchAssignedLabores({
    required String fecha,
    required String processName,
  }) async {
    final currentUser = await _resolveCurrentUser();
    final currentUserDni = currentUser['dni']?.toString();
    final currentUserId = _asInt(
      currentUser['operador_id'] ?? currentUser['user_id'],
    );

    if (currentUserDni == null || currentUserDni.isEmpty) {
      return const [];
    }

    final processId = await _authorizationRepository
        .findAuthorizedProcessIdByName(currentUserDni, processName);

    if (processId == null) {
      return const [];
    }

    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      return _loadFromLocalCache(
        fecha: fecha,
        procesoId: processId,
        userId: currentUserId,
      );
    }

    final uri = Uri.parse(
      '$_baseUrl${ApiConfig.misLaboresEndpoint}',
    ).replace(queryParameters: {'fecha': fecha, 'proceso_id': '$processId'});

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al obtener mis labores. Codigo: ${response.statusCode}',
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('La respuesta de mis-labores debe ser un objeto JSON.');
      }

      final laboresRows = _extractLaboresRows(decoded);
      await _databaseHelper.replaceLocalPlanLabores(
        fecha: fecha,
        procesoId: processId,
        userId: _asInt(decoded['user_id']) ?? currentUserId,
        turno: decoded['turno']?.toString(),
        turnoCodigo:
            decoded['turno_codigo']?.toString() ??
            decoded['turno_id']?.toString(),
        procesoNombre: decoded['proceso_nombre']?.toString() ?? processName,
        labores: laboresRows,
      );

      return laboresRows.map(AssignedLabor.fromJson).toList();
    } catch (_) {
      return _loadFromLocalCache(
        fecha: fecha,
        procesoId: processId,
        userId: currentUserId,
      );
    }
  }

  Future<void> prefetchAssignedLaboresForDate({required String fecha}) async {
    final currentUser = await _resolveCurrentUser();
    final currentUserDni = currentUser['dni']?.toString();

    if (currentUserDni == null || currentUserDni.isEmpty) {
      return;
    }

    final authorizedProcesses = await _authorizationRepository
        .getAuthorizedProcesses(currentUserDni);

    final uniqueProcessNames = <String>{};
    for (final process in authorizedProcesses) {
      final name = process.name.trim();
      if (name.isNotEmpty) {
        uniqueProcessNames.add(name);
      }
    }

    for (final processName in uniqueProcessNames) {
      try {
        await fetchAssignedLabores(fecha: fecha, processName: processName);
      } catch (_) {
        // Ignorar fallos individuales para no bloquear la precarga.
      }
    }
  }

  Future<Map<String, dynamic>> _resolveCurrentUser() async {
    final currentUserDni = await _databaseHelper.getCurrentUserDni();
    if (currentUserDni == null || currentUserDni.isEmpty) {
      return const {};
    }

    final user = await _databaseHelper.getUserByDni(currentUserDni);
    return {
      'dni': currentUserDni,
      'operador_id': user?['operador_id'],
      'user_id': user?['user_id'],
    };
  }

  List<Map<String, dynamic>> _extractLaboresRows(Map<String, dynamic> decoded) {
    final labores = decoded['labores'];
    if (labores is! List) {
      return const [];
    }

    return labores
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  Future<List<AssignedLabor>> _loadFromLocalCache({
    required String fecha,
    required int procesoId,
    int? userId,
  }) async {
    final rows = await _databaseHelper.getLocalPlanLabores(
      fecha: fecha,
      procesoId: procesoId,
      userId: userId,
    );

    return rows.map(AssignedLabor.fromJson).toList();
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}
