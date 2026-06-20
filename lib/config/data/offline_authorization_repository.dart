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
    Database? database,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper(),
       _database = database;

  final DatabaseHelper _databaseHelper;
  final Database? _database;

  Future<Database> get _resolvedDatabase async =>
      _database ?? _databaseHelper.database;

  Future<Set<int>> getAuthorizedProcessIds(String dni) async {
    final db = await _resolvedDatabase;
    final rows = await db.query(
      'UsuarioProceso',
      columns: ['proceso_id'],
      where: 'codigo_dni = ?',
      whereArgs: [dni],
    );

    return rows.map((row) => row['proceso_id']).whereType<int>().toSet();
  }

  Future<bool> hasNormalizedProcessAuth(String dni) async {
    final db = await _resolvedDatabase;
    final rows = await db.query(
      'UsuarioProceso',
      columns: ['proceso_id'],
      where: 'codigo_dni = ?',
      whereArgs: [dni],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<List<AuthorizedProcess>> getAuthorizedProcesses(String dni) async {
    final userDb = await _databaseHelper.database;
    final sharedDb = await _databaseHelper.sharedCatalogDatabase;

    final rows = await userDb.query(
      'UsuarioProceso',
      columns: ['proceso_id'],
      where: 'codigo_dni = ?',
      whereArgs: [dni],
    );

    final processIds = rows.map((r) => r['proceso_id']).whereType<int>().toList();
    if (processIds.isEmpty) return [];

    final placeholders = processIds.map((_) => '?').join(',');
    final sharedRows = await sharedDb.rawQuery(
      'SELECT id, nombre FROM procesos WHERE id IN ($placeholders) ORDER BY id ASC',
      processIds,
    );

    final idToName = {
      for (final r in sharedRows)
        r['id'] as int: r['nombre']?.toString() ?? '',
    };

    return processIds
        .map((id) => AuthorizedProcess(id: id, name: idToName[id] ?? ''))
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

    final db = await _resolvedDatabase;
    final users = await db.query(
      'Usuario',
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
    final db = await _resolvedDatabase;
    final rows = await db.query(
      'UsuarioEquipo',
      columns: ['equipo_id'],
      where: 'codigo_dni = ? AND proceso_id = ?',
      whereArgs: [dni, processId],
    );

    return rows.map((row) => row['equipo_id']).whereType<int>().toSet();
  }
}
