import 'package:i_miner/config/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class SyncRepository {
  SyncRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  Future<Database> get _db async => _databaseHelper.database;

  /// Get ALL operations from a table, normalized for sync UI display.
  Future<List<Map<String, dynamic>>> getAllOperations(String tableName) async {
    return _normalizedRows(tableName);
  }

  /// Get operations that are closed (cerrado=1) but not yet sent (enviado=0).
  Future<List<Map<String, dynamic>>> getUnsentOperations(
    String tableName,
  ) async {
    return _normalizedRows(
      tableName,
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  /// Mark a single operation as sent.
  Future<void> markAsSent(String tableName, int id) async {
    final db = await _db;
    await db.update(
      tableName,
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Query with normalization for sync consumers.
  /// Adds 'envio' alias and 'estado' for compatibility.
  Future<List<Map<String, dynamic>>> _normalizedRows(
    String tableName, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );
    return rows.map((row) {
      final normalized = Map<String, dynamic>.from(row);
      final enviado = (row['enviado'] as int?) ?? 0;
      final cerrado = (row['cerrado'] as int?) ?? 0;
      normalized['envio'] = enviado;
      normalized['estado'] = cerrado == 1 ? 'cerrado' : 'activo';
      normalized['jefeGuardia'] = row['jefe_guardia'];
      return normalized;
    }).toList();
  }
}
