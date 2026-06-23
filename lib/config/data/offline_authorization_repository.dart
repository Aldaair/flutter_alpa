import 'dart:convert';

import 'package:i_miner/config/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AuthorizedProcess {
  const AuthorizedProcess({required this.id, required this.name});

  final int id;
  final String name;
}

String normalizeAuthorizationName(String value) {
  const replacements = {
    'Á': 'A',
    'É': 'E',
    'Í': 'I',
    'Ó': 'O',
    'Ú': 'U',
    'Ü': 'U',
    'á': 'A',
    'é': 'E',
    'í': 'I',
    'ó': 'O',
    'ú': 'U',
    'ü': 'U',
  };

  final buffer = StringBuffer();
  for (final rune in value.trim().runes) {
    buffer.write(
      replacements[String.fromCharCode(rune)] ?? String.fromCharCode(rune),
    );
  }

  return buffer.toString().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
}

class OfflineAuthorizationRepository {
  OfflineAuthorizationRepository({
    DatabaseHelper? databaseHelper,
    Database? userDatabase,
    Database? sharedDatabase,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper(),
       _sharedDatabase = sharedDatabase;

  final DatabaseHelper _databaseHelper;
  final Database? _sharedDatabase;

  Future<Database> get _sharedDb async =>
      _sharedDatabase ?? _databaseHelper.sharedCatalogDatabase;

  Future<int?> _getOperadorId(String dni) async {
    final db = await _sharedDb;
    final rows = await db.query(
      'usuario_directorio',
      columns: ['operador_id'],
      where: 'codigo_dni = ?',
      whereArgs: [dni],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['operador_id'] as int?;
  }

  Future<Set<int>> getAuthorizedProcessIds(String dni) async {
    final operadorId = await _getOperadorId(dni);
    if (operadorId == null) return {};

    final db = await _sharedDb;
    final rows = await db.query(
      'usuario_procesos',
      columns: ['proceso_id'],
      where: 'usuarios_id = ?',
      whereArgs: [operadorId],
    );

    return rows.map((row) => row['proceso_id']).whereType<int>().toSet();
  }

  Future<bool> hasNormalizedProcessAuth(String dni) async {
    final operadorId = await _getOperadorId(dni);
    if (operadorId == null) return false;

    final db = await _sharedDb;
    final rows = await db.query(
      'usuario_procesos',
      columns: ['proceso_id'],
      where: 'usuarios_id = ?',
      whereArgs: [operadorId],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<List<AuthorizedProcess>> getAuthorizedProcesses(String dni) async {
    final operadorId = await _getOperadorId(dni);
    if (operadorId == null) return [];

    final db = await _sharedDb;
    final rows = await db.rawQuery(
      'SELECT up.proceso_id, p.nombre '
      'FROM usuario_procesos up '
      'JOIN procesos p ON up.proceso_id = p.id '
      'WHERE up.usuarios_id = ? '
      'ORDER BY p.id ASC',
      [operadorId],
    );

    return rows
        .map(
          (r) => AuthorizedProcess(
            id: r['proceso_id'] as int,
            name: r['nombre']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<int?> findAuthorizedProcessIdByName(
    String dni,
    String processName,
  ) async {
    final normalizedTarget = normalizeAuthorizationName(processName);
    final processes = await getAuthorizedProcesses(dni);

    for (final process in processes) {
      if (normalizeAuthorizationName(process.name) == normalizedTarget) {
        return process.id;
      }
    }

    return null;
  }

  Future<bool> isDashboardProcessAuthorized(
    String dni,
    int processId,
    String legacyKey,
  ) async {
    if (await hasNormalizedProcessAuth(dni)) {
      final processIds = await getAuthorizedProcessIds(dni);
      return processIds.contains(processId);
    }

    final db = await _sharedDb;
    final users = await db.query(
      'usuario_directorio',
      columns: ['operaciones_autorizadas'],
      where: 'codigo_dni = ?',
      whereArgs: [dni],
      limit: 1,
    );

    if (users.isEmpty) {
      return false;
    }

    final rawValue = users.first['operaciones_autorizadas'];
    if (rawValue is! String || rawValue.isEmpty) {
      return false;
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! Map<String, dynamic>) {
      return false;
    }

    return decoded[legacyKey] == true;
  }

  Future<Set<int>> getAuthorizedEquipoIds({
    required String dni,
    required int processId,
  }) async {
    final operadorId = await _getOperadorId(dni);
    if (operadorId == null) return {};
    final db = await _sharedDb;
    final rows = await db.query(
      'usuario_equipos',
      columns: ['equipo_id'],
      where: 'usuarios_id = ? AND proceso_id = ?',
      whereArgs: [operadorId, processId],
    );

    return rows.map((row) => row['equipo_id']).whereType<int>().toSet();
  }
}
