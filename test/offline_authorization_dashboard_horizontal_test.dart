import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/Equipo.dart';
import 'package:i_miner/screens/Dash/reporte_sreen.dart';
import 'package:i_miner/screens/Operaciones/Tal%20horizontal/widgets/operacion_card.dart';
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
    tempDir = await Directory.systemTemp.createTemp('offline_authz_ui_test');
    dbHelper = DatabaseHelper();
  });

  tearDown(() async {
    await dbHelper.closeDatabase();
    DatabaseHelper.setDatabasePathOverride(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('dashboard prefers normalized process authorization over legacy JSON', () async {
    final dbPath = p.join(tempDir.path, 'dashboard_normalized.db');
    DatabaseHelper.setDatabasePathOverride(dbPath);
    await dbHelper.setCurrentUserDni('70000001');

    await dbHelper.saveUserProfileSnapshot({
      'codigo_dni': '70000001',
      'operador_id': 70,
      'apellidos': 'Perez',
      'nombres': 'Ana',
      'cargo': 'Operador',
      'empresa': 'Seminco',
      'guardia': 'A',
      'autorizado_equipo': 'legacy-equipment',
      'area': 'Mina',
      'clasificacion': 'A1',
      'correo': 'ana@example.com',
      'firma': 'firma',
      'rol': 'user',
      'operaciones_autorizadas': {
        'PERFORACIÓN HORIZONTAL': false,
        'SOSTENIMIENTO': true,
      },
      'normalized_authorization': {
        'procesos': [
          {'id': 7, 'nombre': 'Taladro Horizontal'},
        ],
        'usuario_procesos': [
          {'codigo_dni': '70000001', 'proceso_id': 7},
        ],
        'usuario_equipos': [],
      },
    }, password: 'secret');

    final authorization = await loadDashboardAuthorizationState(dni: '70000001');

    expect(authorization['PERFORACIÓN HORIZONTAL'], isTrue);
    expect(authorization['SOSTENIMIENTO'], isFalse);
  });

  test('dashboard falls back to legacy authorization before normalized rows exist', () async {
    final dbPath = p.join(tempDir.path, 'dashboard_legacy.db');
    DatabaseHelper.setDatabasePathOverride(dbPath);
    await dbHelper.setCurrentUserDni('70000002');

    await dbHelper.saveUserProfileSnapshot({
      'codigo_dni': '70000002',
      'operador_id': 71,
      'apellidos': 'Quispe',
      'nombres': 'Luis',
      'cargo': 'Supervisor',
      'empresa': 'Seminco',
      'guardia': 'B',
      'autorizado_equipo': 'legacy-equipment',
      'area': 'Mina',
      'clasificacion': 'A1',
      'correo': 'luis@example.com',
      'firma': 'firma',
      'rol': 'user',
      'operaciones_autorizadas': {
        'PERFORACIÓN HORIZONTAL': true,
        'SOSTENIMIENTO': false,
      },
      'normalized_authorization': {
        'procesos': [],
        'usuario_procesos': [],
        'usuario_equipos': [],
      },
    }, password: 'secret');

    final authorization = await loadDashboardAuthorizationState(dni: '70000002');

    expect(authorization['PERFORACIÓN HORIZONTAL'], isTrue);
    expect(authorization['SOSTENIMIENTO'], isFalse);
  });

  test('taladro horizontal returns only repository-authorized equipment', () async {
    final dbPath = p.join(tempDir.path, 'horizontal_equipment.db');
    DatabaseHelper.setDatabasePathOverride(dbPath);
    await dbHelper.setCurrentUserDni('70000003');
    final db = await dbHelper.database;

    await dbHelper.saveUserProfileSnapshot({
      'codigo_dni': '70000003',
      'operador_id': 72,
      'apellidos': 'Rojas',
      'nombres': 'Mia',
      'cargo': 'Operador',
      'empresa': 'Seminco',
      'guardia': 'C',
      'autorizado_equipo': '10,11,12',
      'area': 'Mina',
      'clasificacion': 'A1',
      'correo': 'mia@example.com',
      'firma': 'firma',
      'rol': 'user',
      'operaciones_autorizadas': {'PERFORACIÓN HORIZONTAL': true},
      'normalized_authorization': {
        'procesos': [
          {'id': 7, 'nombre': 'Taladro Horizontal'},
        ],
        'usuario_procesos': [
          {'codigo_dni': '70000003', 'proceso_id': 7},
        ],
        'usuario_equipos': [
          {'codigo_dni': '70000003', 'proceso_id': 7, 'equipo_id': 10},
        ],
      },
    }, password: 'secret');

    await db.insert('Equipo', _equipoRow(id: 10, nombre: 'Alpha'));
    await db.insert('Equipo', _equipoRow(id: 11, nombre: 'Beta'));
    await db.insert(
      'Equipo',
      _equipoRow(id: 12, nombre: 'Gamma', proceso: 'SOSTENIMIENTO'),
    );

    final equipos = await loadAuthorizedHorizontalEquipos(dni: '70000003');

    expect(equipos.map((equipo) => equipo.id).toList(), [10]);
    expect(equipos.map((equipo) => equipo.nombre).toList(), ['Alpha']);
  });

  test('taladro horizontal stays open with an empty equipment list', () async {
    final dbPath = p.join(tempDir.path, 'horizontal_empty_equipment.db');
    DatabaseHelper.setDatabasePathOverride(dbPath);
    await dbHelper.setCurrentUserDni('70000004');
    final db = await dbHelper.database;

    await dbHelper.saveUserProfileSnapshot({
      'codigo_dni': '70000004',
      'operador_id': 73,
      'apellidos': 'Lopez',
      'nombres': 'Jose',
      'cargo': 'Operador',
      'empresa': 'Seminco',
      'guardia': 'D',
      'autorizado_equipo': '10,11',
      'area': 'Mina',
      'clasificacion': 'A1',
      'correo': 'jose@example.com',
      'firma': 'firma',
      'rol': 'user',
      'operaciones_autorizadas': {'PERFORACIÓN HORIZONTAL': true},
      'normalized_authorization': {
        'procesos': [
          {'id': 7, 'nombre': 'Taladro Horizontal'},
        ],
        'usuario_procesos': [
          {'codigo_dni': '70000004', 'proceso_id': 7},
        ],
        'usuario_equipos': [],
      },
    }, password: 'secret');

    await db.insert('Equipo', _equipoRow(id: 10, nombre: 'Alpha'));
    await db.insert('Equipo', _equipoRow(id: 11, nombre: 'Beta'));

    final equipos = await loadAuthorizedHorizontalEquipos(dni: '70000004');

    expect(equipos, isEmpty);
  });
}

Map<String, dynamic> _equipoRow({
  required int id,
  required String nombre,
  String proceso = 'PERFORACIÓN HORIZONTAL',
}) {
  return Equipo(
    id: id,
    nombre: nombre,
    proceso: proceso,
    codigo: 'EQ-$id',
    marca: 'Atlas',
    modelo: 'M$id',
    serie: 'SER-$id',
    anioFabricacion: 2024,
    fechaIngreso: '2024-01-01',
  ).toMap();
}
