import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/horizontal_catalog_repository.dart';
import 'package:i_miner/config/data/offline_authorization_repository.dart';
import 'package:i_miner/models/Equipo.dart';
import 'package:i_miner/models/JefeGuardia.dart';
import 'package:i_miner/models/Seccion.dart';
import 'package:i_miner/models/zona.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('horizontal catalog models preserve backend identity and labels', () {
    final equipo = Equipo.fromJson({
      'id': '10',
      'nombre': 'Alpha',
      'proceso': 'PERFORACION HORIZONTAL',
      'codigo': 'EQ-10',
      'marca': 'Atlas',
      'modelo': 'M1',
      'serie': 'SER-10',
      'anioFabricacion': '2020',
      'fechaIngreso': '2024-01-01',
      'capacidadYd3': '1.5',
      'capacidadM3': 2,
    });
    final seccion = Seccion.fromJson({
      'id': '30',
      'proceso': 'PERFORACION HORIZONTAL',
      'nombre': 'Seccion A',
    });
    final jefe = JefeGuardia.fromJson({
      'id': '40',
      'nombres': 'Luis',
      'apellidos': 'Rojas',
    });

    expect(equipo.id, 10);
    expect(equipo.nombre, 'Alpha');
    expect(equipo.codigo, 'EQ-10');
    expect(equipo.capacidadYd3, 1.5);
    expect(equipo.capacidadM3, 2);
    expect(seccion.id, 30);
    expect(seccion.nombre, 'Seccion A');
    expect(jefe.id, 40);
    expect(jefe.apellidos, 'Rojas');
  });

  late Directory tempDir;
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('horizontal_identity_test');
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
    'migrates version 20 schema to latest with horizontal identity and auth tables',
    () async {
      final dbPath = p.join(tempDir.path, 'migration.db');
      await _createVersion20Database(dbPath);

      DatabaseHelper.setDatabasePathOverride(dbPath);
      await dbHelper.setCurrentUserDni('12345678');
      final db = await dbHelper.database;

      final usuarioColumns = await db.rawQuery('PRAGMA table_info(Usuario)');
      final horizontalColumns = await db.rawQuery(
        'PRAGMA table_info(Operacion_tal_horizontal)',
      );
      expect(_hasColumn(usuarioColumns, 'operador_id'), isTrue);
      expect(_hasColumn(horizontalColumns, 'operador_id'), isTrue);
      expect(_hasColumn(horizontalColumns, 'equipo_id'), isTrue);
      expect(_hasColumn(horizontalColumns, 'seccion_id'), isTrue);
      expect(_hasColumn(horizontalColumns, 'jefe_guardia_id'), isTrue);
      expect(_hasColumn(horizontalColumns, 'identity_version'), isTrue);
      expect(_hasColumn(horizontalColumns, 'syncable'), isTrue);

      final migratedRow = await db.query('Operacion_tal_horizontal');
      expect(migratedRow.single['identity_version'], 0);
      expect(migratedRow.single['syncable'], 0);
    },
  );

  test('returns only syncable api v2 horizontal rows pending export', () async {
    final dbPath = p.join(tempDir.path, 'pending_rows.db');
    DatabaseHelper.setDatabasePathOverride(dbPath);
    await dbHelper.setCurrentUserDni('11111111');
    final db = await dbHelper.database;

    await db.insert('Operacion_tal_horizontal', {
      'fecha': '2026-06-17',
      'turno': 'Dia',
      'estado': 'cerrado',
      'envio': 0,
      'identity_version': 2,
      'syncable': 1,
    });
    await db.insert('Operacion_tal_horizontal', {
      'fecha': '2026-06-17',
      'turno': 'Dia',
      'estado': 'cerrado',
      'envio': 0,
      'identity_version': 2,
      'syncable': 0,
    });
    await db.insert('Operacion_tal_horizontal', {
      'fecha': '2026-06-17',
      'turno': 'Dia',
      'estado': 'cerrado',
      'envio': 0,
      'identity_version': 0,
      'syncable': 1,
    });

    final pending = await dbHelper.getOperacionesTaladroHorizontalNoEnviadas();

    expect(pending, hasLength(1));
    expect(pending.first['identity_version'], 2);
    expect(pending.first['syncable'], 1);
  });

  test(
    'insertOperacionTalHorizontal persists api v2 identity fields',
    () async {
      final dbPath = p.join(tempDir.path, 'insert_horizontal.db');
      DatabaseHelper.setDatabasePathOverride(dbPath);
      await dbHelper.setCurrentUserDni('33333333');

      final id = await dbHelper.insertOperacionTalHorizontal(
        '2026-06-17',
        'Dia',
        'Seccion A',
        'Ana Perez',
        'Luis Rojas',
        'Alpha',
        'EQ-10',
        'M1',
        operadorId: 44,
        equipoId: 10,
        zonaId: 30,
        jefeGuardiaId: 40,
      );

      final db = await dbHelper.database;
      final rows = await db.query(
        'Operacion_tal_horizontal',
        where: 'id = ?',
        whereArgs: [id],
      );

      expect(rows, hasLength(1));
      expect(rows.single['operador_id'], 44);
      expect(rows.single['equipo_id'], 10);
      expect(rows.single['seccion_id'], 30);
      expect(rows.single['jefe_guardia_id'], 40);
      expect(rows.single['identity_version'], 2);
      expect(rows.single['syncable'], 1);
    },
  );

  test(
    'refreshes horizontal catalogs by remote id and prunes missing rows',
    () async {
      final dbPath = p.join(tempDir.path, 'catalogs.db');
      DatabaseHelper.setDatabasePathOverride(dbPath);
      await dbHelper.setCurrentUserDni('22222222');
      final db = await dbHelper.database;
      final repository = HorizontalCatalogRepository(database: db);

      await repository.refreshEquipos([
        Equipo(
          id: 10,
          nombre: 'Alpha',
          proceso: 'PERFORACIÓN HORIZONTAL',
          codigo: 'EQ-10',
          marca: 'Atlas',
          modelo: 'M1',
          serie: 'SER-10',
          anioFabricacion: 2020,
          fechaIngreso: '2024-01-01',
        ),
        Equipo(
          id: 20,
          nombre: 'Beta',
          proceso: 'PERFORACIÓN HORIZONTAL',
          codigo: 'EQ-20',
          marca: 'Atlas',
          modelo: 'M2',
          serie: 'SER-20',
          anioFabricacion: 2021,
          fechaIngreso: '2024-01-02',
        ),
      ]);
      await repository.refreshZonas([
        Zona(id: 30, proceso: 'PERFORACIÓN HORIZONTAL', nombre: 'Seccion A'),
      ]);
      await repository.refreshJefesGuardia([
        JefeGuardia(id: 40, nombres: 'Luis', apellidos: 'Rojas'),
      ]);

      await repository.refreshEquipos([
        Equipo(
          id: 10,
          nombre: 'Alpha Renamed',
          proceso: 'PERFORACIÓN HORIZONTAL',
          codigo: 'EQ-10',
          marca: 'Atlas',
          modelo: 'M1',
          serie: 'SER-10',
          anioFabricacion: 2020,
          fechaIngreso: '2024-01-01',
        ),
      ]);
      await repository.refreshZonas([
        Zona(id: 30, proceso: 'PERFORACIÓN HORIZONTAL', nombre: 'Seccion A2'),
      ]);
      await repository.refreshJefesGuardia([
        JefeGuardia(id: 40, nombres: 'Luis', apellidos: 'Quispe'),
      ]);

      final equipos = await db.query('Equipo', orderBy: 'id ASC');
      final secciones = await db.query('Seccion');
      final jefes = await db.query('jefe_guardias');

      expect(equipos, hasLength(1));
      expect(equipos.first['id'], 10);
      expect(equipos.first['nombre'], 'Alpha Renamed');
      expect(secciones.single['id'], 30);
      expect(secciones.single['nombre'], 'Seccion A2');
      expect(jefes.single['id'], 40);
      expect(jefes.single['apellidos'], 'Quispe');
    },
  );
}

Future<void> _createVersion20Database(String path) async {
  final db = await openDatabase(
    path,
    version: 20,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE Usuario (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          codigo_dni TEXT NOT NULL UNIQUE,
          apellidos TEXT NOT NULL,
          nombres TEXT NOT NULL,
          cargo TEXT,
          empresa TEXT,
          guardia TEXT,
          autorizado_equipo TEXT,
          area TEXT,
          clasificacion TEXT,
          correo TEXT,
          password TEXT NOT NULL,
          firma TEXT,
          rol TEXT,
          operaciones_autorizadas TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE Operacion_tal_horizontal (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT,
          turno TEXT,
          seccion TEXT,
          operador TEXT,
          jefe_guardia TEXT,
          equipo TEXT,
          n_equipo TEXT,
          modelo_equipo TEXT,
          registros TEXT,
          horometros TEXT,
          condiciones_equipo TEXT,
          check_list TEXT,
          control_llantas TEXT,
          estado TEXT DEFAULT 'activo',
          envio INTEGER DEFAULT 0
        )
      ''');

      await db.insert('Operacion_tal_horizontal', {
        'fecha': '2026-06-17',
        'turno': 'Dia',
        'seccion': 'Legacy Section',
        'operador': 'Legacy Operator',
        'jefe_guardia': 'Legacy Guard',
        'equipo': 'Legacy Equipo',
        'n_equipo': 'LEG-1',
        'modelo_equipo': 'Legacy Model',
        'estado': 'cerrado',
        'envio': 0,
      });
    },
  );

  await db.close();
}

bool _hasColumn(List<Map<String, Object?>> columns, String name) {
  return columns.any((column) => column['name'] == name);
}
