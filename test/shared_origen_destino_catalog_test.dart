import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/shared_catalog_repository.dart';
import 'package:i_miner/models/destino.dart';
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
    tempDir = await Directory.systemTemp.createTemp(
      'shared_origen_destino_test',
    );
    dbHelper = DatabaseHelper();
  });

  tearDown(() async {
    await dbHelper.closeDatabase();
    DatabaseHelper.setDatabasePathOverride(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Destino preserves origen_destino payload fields', () {
    final destino = Destino.fromJson({
      'id': 7,
      'proceso': 'ACARREO',
      'proceso_id': 4,
      'tipo': 'DESTINO',
      'nombre': 'Tolva 12',
      'tipo_equipo': 'LOCOMOTORA',
    });

    expect(destino.proceso, 'ACARREO');
    expect(destino.procesoId, 4);
    expect(destino.tipo, 'DESTINO');
    expect(destino.tipoEquipo, 'LOCOMOTORA');
    expect(destino.toMap(), {
      'id': 7,
      'proceso': 'ACARREO',
      'proceso_id': 4,
      'tipo': 'DESTINO',
      'nombre': 'Tolva 12',
      'tipo_equipo': 'LOCOMOTORA',
    });
  });

  test('getDestinosByProcesoId reads shared origen_destino rows', () async {
    final dbPath = p.join(tempDir.path, 'user.db');
    DatabaseHelper.setDatabasePathOverride(dbPath);

    final db = await dbHelper.sharedCatalogDatabase;
    final repository = SharedCatalogRepository(databaseHelper: dbHelper);

    await db.insert('origen_destino', {
      'id': 1,
      'proceso': 'ACARREO',
      'proceso_id': 4,
      'tipo': 'DESTINO',
      'nombre': 'Tolva Norte',
      'tipo_equipo': 'LOCOMOTORA',
    });
    await db.insert('origen_destino', {
      'id': 2,
      'proceso': 'ACARREO',
      'proceso_id': 4,
      'tipo': 'DESTINO',
      'nombre': 'Tolva Sur',
      'tipo_equipo': 'VOLQUETE',
    });
    await db.insert('origen_destino', {
      'id': 3,
      'proceso': 'CARGUIO',
      'proceso_id': 5,
      'tipo': 'DESTINO',
      'nombre': 'Cancha 5',
      'tipo_equipo': null,
    });

    final destinos = await repository.getDestinosByProcesoId(4);

    expect(destinos.map((row) => row['nombre']), ['Tolva Norte', 'Tolva Sur']);
    expect(destinos.map((row) => row['tipo_equipo']), [
      'LOCOMOTORA',
      'VOLQUETE',
    ]);
    expect(destinos.every((row) => row['proceso_id'] == 4), isTrue);
  });

  test(
    'getOrigenDestinoByProcesoAndTipo reads shared ORIGEN rows only',
    () async {
      final dbPath = p.join(tempDir.path, 'user.db');
      DatabaseHelper.setDatabasePathOverride(dbPath);

      final db = await dbHelper.sharedCatalogDatabase;
      final repository = SharedCatalogRepository(databaseHelper: dbHelper);

      await db.insert('origen_destino', {
        'id': 1,
        'proceso': 'ACARREO',
        'proceso_id': 4,
        'tipo': 'ORIGEN',
        'nombre': 'Tolva de carga',
        'tipo_equipo': null,
      });
      await db.insert('origen_destino', {
        'id': 2,
        'proceso': 'ACARREO',
        'proceso_id': 4,
        'tipo': 'DESTINO',
        'nombre': 'Tolva final',
        'tipo_equipo': 'VOLQUETE',
      });
      await db.insert('origen_destino', {
        'id': 3,
        'proceso': 'CARGUIO',
        'proceso_id': 5,
        'tipo': 'ORIGEN',
        'nombre': 'Cancha 2',
        'tipo_equipo': null,
      });

      final origenes = await repository.getOrigenDestinoByProcesoAndTipo(
        proceso: 'acarreo',
        tipo: 'origen',
      );

      expect(origenes.map((row) => row['nombre']), ['Tolva de carga']);
      expect(origenes.every((row) => row['tipo'] == 'ORIGEN'), isTrue);
      expect(origenes.every((row) => row['proceso'] == 'ACARREO'), isTrue);
    },
  );

  test(
    'DatabaseHelper.getOrigenDestino uses shared catalog database',
    () async {
      final userDbPath = p.join(tempDir.path, 'user.db');
      DatabaseHelper.setDatabasePathOverride(userDbPath);

      final sharedDb = await dbHelper.sharedCatalogDatabase;
      final userDb = await openDatabase(
        userDbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE origen_destino (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              proceso TEXT,
              tipo TEXT,
              nombre TEXT
            )
          ''');
        },
      );

      await sharedDb.insert('origen_destino', {
        'id': 1,
        'proceso': 'ACARREO',
        'proceso_id': 4,
        'tipo': 'ORIGEN',
        'nombre': 'Tolva compartida',
        'tipo_equipo': null,
      });
      await userDb.insert('origen_destino', {
        'id': 99,
        'proceso': 'ACARREO',
        'tipo': 'ORIGEN',
        'nombre': 'Tolva usuario',
      });

      final origenes = await dbHelper.getOrigenDestino('acarreo', 'origen');

      expect(origenes.map((row) => row['nombre']), ['Tolva compartida']);

      await userDb.close();
    },
  );

  test(
    'shared catalog migration adds origen_destino without deleting destinos',
    () async {
      final userDbPath = p.join(tempDir.path, 'user.db');
      final sharedDbPath = p.join(tempDir.path, 'Seminco_shared_catalogs.db');

      await _createVersion39SharedCatalogDatabase(sharedDbPath);

      DatabaseHelper.setDatabasePathOverride(userDbPath);
      final db = await dbHelper.sharedCatalogDatabase;
      final origenDestinoColumns = await db.rawQuery(
        'PRAGMA table_info(origen_destino)',
      );
      final destinosColumns = await db.rawQuery('PRAGMA table_info(destinos)');

      expect(_hasColumn(origenDestinoColumns, 'proceso'), isTrue);
      expect(_hasColumn(origenDestinoColumns, 'proceso_id'), isTrue);
      expect(_hasColumn(origenDestinoColumns, 'tipo'), isTrue);
      expect(_hasColumn(origenDestinoColumns, 'nombre'), isTrue);
      expect(_hasColumn(origenDestinoColumns, 'tipo_equipo'), isTrue);
      expect(_hasColumn(destinosColumns, 'proceso_id'), isTrue);
      expect(_hasColumn(destinosColumns, 'tipo_equipo'), isTrue);
    },
  );
}

Future<void> _createVersion39SharedCatalogDatabase(String path) async {
  final db = await openDatabase(
    path,
    version: 39,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE destinos (
          id INTEGER PRIMARY KEY,
          nombre TEXT NOT NULL,
          proceso_id INTEGER NOT NULL,
          tipo_equipo TEXT
        )
      ''');
    },
  );

  await db.close();
}

bool _hasColumn(List<Map<String, Object?>> columns, String name) {
  return columns.any((column) => column['name'] == name);
}
