import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/shared_catalog_repository.dart';
import 'package:i_miner/models/EstadostBD.dart';
import 'package:i_miner/shared/acarreo_equipment_type.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('acarreo_estados_test');
    dbHelper = DatabaseHelper();
  });

  tearDown(() async {
    await dbHelper.closeDatabase();
    DatabaseHelper.setDatabasePathOverride(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('EstadostBD preserves tipo_equipo from API payloads', () {
    final estado = EstadostBD.fromJson({
      'id': 1,
      'codigo': 'OP-01',
      'tipo_estado': 'Operativo',
      'categoria': 'OPERATIVO',
      'proceso': 'ACARREO',
      'proceso_id': 4,
      'categoria_id': 2,
      'tipo_equipo': 'VOLQUETE',
    });

    expect(estado.tipoEquipo, 'VOLQUETE');
    expect(estado.toMap()['tipo_equipo'], 'VOLQUETE');
  });

  test('resolveAcarreoTipoEquipoFromName maps supported equipment names', () {
    expect(resolveAcarreoTipoEquipoFromName('Locomotora CZM-01'), 'LOCOMOTORA');
    expect(resolveAcarreoTipoEquipoFromName('Volquete MT-42'), 'VOLQUETE');
    expect(resolveAcarreoTipoEquipoFromName('Scoop ST-14'), isNull);
  });

  test(
    'getEstadosByProcesoAndCategoria optionally filters by tipo_equipo',
    () async {
      final dbPath = p.join(tempDir.path, 'user.db');
      DatabaseHelper.setDatabasePathOverride(dbPath);

      final db = await dbHelper.sharedCatalogDatabase;
      final repository = SharedCatalogRepository(databaseHelper: dbHelper);

      await db.insert('estados', {
        'codigo': 'AC-01',
        'tipo_estado': 'Operativo Volquete',
        'categoria': 'OPERATIVO',
        'proceso': 'ACARREO',
        'proceso_id': 4,
        'categoria_id': 2,
        'tipo_equipo': 'VOLQUETE',
      });
      await db.insert('estados', {
        'codigo': 'AC-02',
        'tipo_estado': 'Operativo Locomotora',
        'categoria': 'OPERATIVO',
        'proceso': 'ACARREO',
        'proceso_id': 4,
        'categoria_id': 2,
        'tipo_equipo': 'LOCOMOTORA',
      });
      await db.insert('estados', {
        'codigo': 'AC-03',
        'tipo_estado': 'Legacy Acarreo',
        'categoria': 'OPERATIVO',
        'proceso': 'ACARREO',
        'proceso_id': 4,
        'categoria_id': 2,
        'tipo_equipo': null,
      });

      final filtered = await repository.getEstadosByProcesoAndCategoria(
        4,
        2,
        tipoEquipo: 'VOLQUETE',
      );
      final unfiltered = await repository.getEstadosByProcesoAndCategoria(4, 2);

      expect(filtered.map((row) => row['codigo']), ['AC-01', 'AC-03']);
      expect(unfiltered.map((row) => row['codigo']), [
        'AC-01',
        'AC-02',
        'AC-03',
      ]);
    },
  );

  test(
    'shared catalog migration adds estados.tipo_equipo for existing installs',
    () async {
      final userDbPath = p.join(tempDir.path, 'user.db');
      final sharedDbPath = p.join(tempDir.path, 'Seminco_shared_catalogs.db');

      await _createVersion38SharedCatalogDatabase(sharedDbPath);

      DatabaseHelper.setDatabasePathOverride(userDbPath);
      final db = await dbHelper.sharedCatalogDatabase;
      final columns = await db.rawQuery('PRAGMA table_info(estados)');

      expect(_hasColumn(columns, 'tipo_equipo'), isTrue);
    },
  );
}

Future<void> _createVersion38SharedCatalogDatabase(String path) async {
  final db = await openDatabase(
    path,
    version: 38,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE estados (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          codigo TEXT NOT NULL,
          tipo_estado TEXT NOT NULL,
          categoria TEXT NOT NULL,
          proceso TEXT NOT NULL,
          proceso_id INTEGER,
          categoria_id INTEGER
        )
      ''');
    },
  );

  await db.close();
}

bool _hasColumn(List<Map<String, Object?>> columns, String name) {
  return columns.any((column) => column['name'] == name);
}
