// lib/services/user_service.dart
import 'dart:convert';

import 'package:i_miner/config/data/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/services/api_service.dart';

class UserProfileContractException implements Exception {
  UserProfileContractException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserService {
  UserService({ApiService? apiService, http.Client? client, String? baseUrl})
    : _apiService = apiService ?? ApiService(),
      _client = client ?? http.Client(),
      baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final ApiService _apiService;
  final http.Client _client;
  final String baseUrl;

  Future<String> login(String codigoDni, String password) async {
    return await _apiService.login(codigoDni, password);
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/usuarios/perfil'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw UserProfileContractException(
          'Invalid /usuarios/perfil response: expected a JSON object.',
        );
      }

      final operadorId = _parseOperadorId(decoded['id']);
      if (operadorId == null) {
        throw UserProfileContractException(
          'Missing required id in /usuarios/perfil response.',
        );
      }

      final normalizedAuthorization = _parseNormalizedAuthorization(decoded);
      print("ga");
      print(decoded);
      return {
        ...decoded,
        'operador_id': operadorId,
        'normalized_authorization': normalizedAuthorization,
      };
    }

    throw Exception('Error al obtener el perfil del usuario');
  }

  Future<Map<String, dynamic>> syncOfflineProfileSnapshot({
    required String dni,
    required String token,
    String? password,
    DatabaseHelper? databaseHelper,
  }) async {
    final dbHelper = databaseHelper ?? DatabaseHelper();
    await dbHelper.setCurrentUserDni(dni);
    final profile = await getUserProfile(token);
    await dbHelper.saveUserProfileSnapshot(profile, password: password);
    return profile;
  }

  int? _parseOperadorId(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _parseNormalizedAuthorization(
    Map<String, dynamic> decoded,
  ) {
    return {
      'procesos': _parseProcesos(decoded['procesos']),
      'usuario_procesos': _parseUsuarioProcesos(decoded['usuario_procesos']),
      'usuario_equipos': _parseUsuarioEquipos(decoded['usuario_equipos']),
    };
  }

  List<Map<String, dynamic>> _parseProcesos(dynamic value) {
    final items = _parseList(value, fieldName: 'procesos');

    return [
      for (var index = 0; index < items.length; index++)
        {
          'id': _parseRequiredInt(
            items[index]['id'],
            fieldName: 'procesos[$index].id',
          ),
          'nombre': _parseRequiredString(
            items[index]['nombre'],
            fieldName: 'procesos[$index].nombre',
          ),
        },
    ];
  }

  List<Map<String, dynamic>> _parseUsuarioProcesos(dynamic value) {
    final items = _parseList(value, fieldName: 'usuario_procesos');

    return [
      for (var index = 0; index < items.length; index++)
        {
          'codigo_dni': _parseRequiredString(
            items[index]['codigo_dni'],
            fieldName: 'usuario_procesos[$index].codigo_dni',
          ),
          'proceso_id': _parseRequiredInt(
            items[index]['proceso_id'],
            fieldName: 'usuario_procesos[$index].proceso_id',
          ),
        },
    ];
  }

  List<Map<String, dynamic>> _parseUsuarioEquipos(dynamic value) {
    final items = _parseList(value, fieldName: 'usuario_equipos');

    return [
      for (var index = 0; index < items.length; index++)
        {
          'codigo_dni': _parseRequiredString(
            items[index]['codigo_dni'],
            fieldName: 'usuario_equipos[$index].codigo_dni',
          ),
          'proceso_id': _parseRequiredInt(
            items[index]['proceso_id'],
            fieldName: 'usuario_equipos[$index].proceso_id',
          ),
          'equipo_id': _parseRequiredInt(
            items[index]['equipo_id'],
            fieldName: 'usuario_equipos[$index].equipo_id',
          ),
        },
    ];
  }

  List<Map<String, dynamic>> _parseList(
    dynamic value, {
    required String fieldName,
  }) {
    if (value is! List) {
      throw UserProfileContractException(
        'Invalid $fieldName in /usuarios/perfil response: expected a list.',
      );
    }

    return [
      for (var index = 0; index < value.length; index++)
        _parseObject(value[index], fieldName: '$fieldName[$index]'),
    ];
  }

  Map<String, dynamic> _parseObject(
    dynamic value, {
    required String fieldName,
  }) {
    if (value is! Map<String, dynamic>) {
      throw UserProfileContractException(
        'Invalid $fieldName in /usuarios/perfil response: expected an object.',
      );
    }

    return value;
  }

  int _parseRequiredInt(dynamic value, {required String fieldName}) {
    final parsed = _parseOperadorId(value);
    if (parsed == null) {
      throw UserProfileContractException(
        'Invalid $fieldName in /usuarios/perfil response: expected an integer.',
      );
    }

    return parsed;
  }

  String _parseRequiredString(dynamic value, {required String fieldName}) {
    final parsed = value?.toString().trim();
    if (parsed == null || parsed.isEmpty) {
      throw UserProfileContractException(
        'Invalid $fieldName in /usuarios/perfil response: expected a non-empty string.',
      );
    }

    return parsed;
  }
}
