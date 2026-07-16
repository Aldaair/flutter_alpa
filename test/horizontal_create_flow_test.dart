import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/config/data/horizontal_create_flow.dart';
import 'package:i_miner/models/Equipo.dart';
import 'package:i_miner/models/JefeGuardia.dart';
import 'package:i_miner/models/zona.dart';
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
    tempDir = await Directory.systemTemp.createTemp('horizontal_create_flow');
    dbHelper = DatabaseHelper();
  });

  tearDown(() async {
    await dbHelper.closeDatabase();
    DatabaseHelper.setDatabasePathOverride(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'buildHorizontalCreatePlan blocks save when required cached IDs are missing',
    () {
      final missingEquipo = buildHorizontalCreatePlan(
        equipoId: null,
        jefeGuardiaId: 40,
        operadorId: 44,
      );
      final missingJefe = buildHorizontalCreatePlan(
        equipoId: 10,
        jefeGuardiaId: null,
        operadorId: 44,
      );

      expect(missingEquipo.isBlocked, isTrue);
      expect(missingEquipo.blockingMessage, contains('equipment ID'));
      expect(missingJefe.isBlocked, isTrue);
      expect(missingJefe.blockingMessage, contains('guard leader ID'));
    },
  );

  test(
    'buildHorizontalCreatePlan allows only a non-syncable draft when operador_id is missing',
    () {
      final plan = buildHorizontalCreatePlan(
        equipoId: 10,
        jefeGuardiaId: 40,
        operadorId: null,
      );

      expect(plan.isBlocked, isFalse);
      expect(plan.identityVersion, 2);
      expect(plan.syncable, isFalse);
    },
  );

  test(
    'buildHorizontalCreatePlan returns a syncable plan when all IDs exist',
    () {
      final plan = buildHorizontalCreatePlan(
        equipoId: 10,
        jefeGuardiaId: 40,
        operadorId: 44,
      );

      expect(plan.isBlocked, isFalse);
      expect(plan.identityVersion, 2);
      expect(plan.syncable, isTrue);
    },
  );

  test('resolved cached rows carry label snapshots and remote IDs', () async {
    final dbPath = p.join(tempDir.path, 'catalog_resolution.db');
    DatabaseHelper.setDatabasePathOverride(dbPath);
    await dbHelper.setCurrentUserDni('55555555');
    final repository = HorizontalCatalogRepository(dbHelper: dbHelper);

    await repository.refreshEquipos([
      Equipo(
        id: 10,
        nombre: 'Boomer',
        proceso: 'PERFORACIÓN HORIZONTAL',
        codigo: 'TH-01',
        marca: 'Epiroc',
        modelo: 'S1D',
        serie: 'SER-01',
        anioFabricacion: 2023,
        fechaIngreso: '2026-01-01',
      ),
    ]);
    await repository.refreshZonas([
      Zona(id: 30, proceso: 'PERFORACIÓN HORIZONTAL', nombre: 'Section 12'),
    ]);
    await repository.refreshJefesGuardia([
      JefeGuardia(id: 40, nombres: 'Luis', apellidos: 'Rojas'),
    ]);

    final equipo = await repository.resolveEquipoSelection(
      nombre: 'Boomer',
      codigo: 'TH-01',
      modelo: 'S1D',
    );
    final seccion = await repository.resolveZonaByNombre(
      'Section 12',
      proceso: 'PERFORACIÓN HORIZONTAL',
    );
    final jefe = await repository.resolveJefeGuardiaByFullName('Luis Rojas');

    expect(equipo, isNotNull);
    expect(equipo!.equipoId, 10);
    expect(equipo.equipo, 'Boomer');
    expect(equipo.codigo, 'TH-01');
    expect(equipo.modelo, 'S1D');
    expect(seccion, isNotNull);
    expect(seccion!.id, 30);
    expect(seccion.nombre, 'Section 12');
    expect(jefe, isNotNull);
    expect(jefe!.id, 40);
    expect('${jefe.nombres} ${jefe.apellidos}', 'Luis Rojas');
  });

  test(
    'insertOperacionTalHorizontal stores a draft with supported persisted fields',
    () async {
      final dbPath = p.join(tempDir.path, 'draft_without_operator.db');
      DatabaseHelper.setDatabasePathOverride(dbPath);
      await dbHelper.setCurrentUserDni('66666666');

      final rowId = await dbHelper.insertOperacionTalHorizontal(
        '2026-06-17',
        'DÍA',
        'Ana Perez',
        'Luis Rojas',
        'Boomer',
        equipoId: 10,
        jefeGuardiaId: 40,
        identityVersion: 2,
        syncable: false ? 1 : 0,
      );

      final db = await dbHelper.database;
      final columns = await db.rawQuery(
        'PRAGMA table_info(Operacion_tal_horizontal)',
      );
      final rows = await db.query(
        'Operacion_tal_horizontal',
        where: 'id = ?',
        whereArgs: [rowId],
      );

      expect(rows.single['operador_id'], isNull);
      expect(rows.single['equipo_id'], 10);
      expect(rows.single['jefe_guardia_id'], 40);
      expect(_hasColumn(columns, 'n_equipo'), isFalse);
      expect(_hasColumn(columns, 'modelo'), isFalse);
      expect(_hasColumn(columns, 'seccion'), isFalse);
    },
  );

  test(
    'insertOperacionTalHorizontal stores equipment identity by equipo_id',
    () async {
      final dbPath = p.join(tempDir.path, 'syncable_with_ids.db');
      DatabaseHelper.setDatabasePathOverride(dbPath);
      await dbHelper.setCurrentUserDni('77777777');

      final rowId = await dbHelper.insertOperacionTalHorizontal(
        '2026-06-17',
        'DÍA',
        'Ana Perez',
        'Luis Rojas',
        'Boomer',
        operadorId: 44,
        equipoId: 10,
        jefeGuardiaId: 40,
        identityVersion: 2,
        syncable: true ? 1 : 0,
      );

      final db = await dbHelper.database;
      final rows = await db.query(
        'Operacion_tal_horizontal',
        where: 'id = ?',
        whereArgs: [rowId],
      );

      expect(rows.single['operador_id'], 44);
      expect(rows.single['equipo_id'], 10);
      expect(rows.single['jefe_guardia_id'], 40);
      expect(rows.single['equipo'], 'Boomer');
    },
  );
}

bool _hasColumn(List<Map<String, Object?>> columns, String name) {
  return columns.any((column) => column['name'] == name);
}
