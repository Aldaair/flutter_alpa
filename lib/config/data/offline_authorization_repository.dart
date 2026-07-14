import 'package:bcrypt/bcrypt.dart';
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
      columns: ['id'],
      where: 'codigo_dni = ?',
      whereArgs: [dni],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as int?;
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

    return false;
  }

  /// Attempt offline login by checking password hash against usuario_directorio.
  Future<bool> loginOffline(String dni, String password) async {
    try {
      final db = await _sharedDb;
      final rows = await db.query(
        'usuario_directorio',
        columns: ['password', 'nombres', 'apellidos', 'rol', 'id'],
        where: 'codigo_dni = ?',
        whereArgs: [dni],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final hash = rows.first['password'] as String?;
        if (hash != null && hash.isNotEmpty) {
          if (BCrypt.checkpw(password, hash)) {
            // Set the current user DNI so the database helper scope is active
            await _databaseHelper.setCurrentUserDni(dni);
            return true;
          }
        }
        return false;
      }
    } catch (_) {}

    return false;
  }

  /// Get user record from usuario_directorio by DNI.
  Future<Map<String, dynamic>?> getUserByDni(String dni) async {
    final db = await _sharedDb;
    final List<Map<String, dynamic>> result = await db.query(
      'usuario_directorio',
      where: 'codigo_dni = ?',
      whereArgs: [dni],
    );

    if (result.isNotEmpty) {
      final user = Map<String, dynamic>.from(result.first);
      user['id'] = user['id'] ?? user['codigo_dni'];
      user['createdAt'] = user['createdAt'] ?? user['updated_at'];
      user['updatedAt'] = user['updated_at'];
      user['password'] = user['password'] ?? '';
      return user;
    }
    return null;
  }

  /// Check if the user has one of the allowed cargo names.
  Future<bool> userHasCargo(String dni, List<String> cargosPermitidos) async {
    final user = await getUserByDni(dni);
    if (user == null) return false;
    final cargoId = user['cargo_id'];
    if (cargoId == null) return false;
    final db = await _sharedDb;
    final result = await db.query(
      'cargos',
      columns: ['nombre'],
      where: 'cargo_id = ?',
      whereArgs: [cargoId],
      limit: 1,
    );
    if (result.isEmpty) return false;
    final nombre =
        (result.first['nombre'] as String?)?.trim().toUpperCase() ?? '';
    return cargosPermitidos.any((c) => c.toUpperCase() == nombre);
  }

  /// Get all known operators from usuario_directorio.
  Future<List<Map<String, dynamic>>> getKnownOperators() async {
    final db = await _sharedDb;
    final users = await db.query('usuario_directorio');
    return users.asMap().entries.map((entry) {
      final u = Map<String, dynamic>.from(entry.value);
      u['id'] = u['id'] ?? entry.key + 1;
      u['nombre_completo'] = '${u['nombres']} ${u['apellidos']}';
      return u;
    }).toList();
  }
}
