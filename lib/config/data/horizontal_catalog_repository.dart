import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/DimPeriodo.dart';
import 'package:i_miner/models/DimMina.dart';
import 'package:i_miner/models/DimZona.dart';
import 'package:i_miner/models/DimArea.dart';
import 'package:i_miner/models/DimFase.dart';
import 'package:i_miner/models/DimTipoLabor.dart';
import 'package:i_miner/models/DimEstructuraMineral.dart';
import 'package:i_miner/models/DimNivel.dart';
import 'package:i_miner/models/DimAla.dart';
import 'package:i_miner/models/DimLabor.dart';
import 'package:i_miner/models/DimTurno.dart';
import 'package:i_miner/models/Equipo.dart';
import 'package:i_miner/models/JefeGuardia.dart';
import 'package:i_miner/models/cargo.dart';
import 'package:i_miner/models/EstadostBD.dart';
import 'package:i_miner/models/Proceso.dart';
import 'package:i_miner/models/zona.dart';
import 'package:sqflite/sqflite.dart';

class HorizontalResolvedEquipoSelection {
  const HorizontalResolvedEquipoSelection({
    required this.equipo,
    required this.codigo,
    required this.modelo,
    required this.equipoId,
  });

  final String equipo;
  final String codigo;
  final String modelo;
  final int? equipoId;
}

class HorizontalCatalogRepository {
  HorizontalCatalogRepository({DatabaseHelper? dbHelper, Database? database})
    : _dbHelper = dbHelper ?? DatabaseHelper(),
      _database = database;

  final DatabaseHelper _dbHelper;
  final Database? _database;

  Future<Database> get _db async =>
      _database ?? await _dbHelper.sharedCatalogDatabase;

  Future<void> refreshEquipos(List<Equipo> equipos) async {
    await _refreshCatalog(
      table: 'Equipo',
      items: equipos.map((equipo) => equipo.toMap()).toList(),
    );
  }

  Future<void> refreshZonas(List<Zona> zonas) async {
    await _refreshCatalog(
      table: 'zona',
      items: zonas.map((zona) => zona.toMap()).toList(),
    );
  }

  Future<void> refreshJefesGuardia(List<JefeGuardia> jefes) async {
    await _refreshCatalog(
      table: 'jefe_guardias',
      items: jefes.map((jefe) => jefe.toMap()).toList(),
    );
  }

  Future<void> refreshPeriodos(List<DimPeriodo> periodos) async {
    await _refreshCatalog(
      table: 'dim_periodo',
      items: periodos.map((periodo) => periodo.toMap()).toList(),
      primaryKeyColumn: 'periodo_id',
    );
  }

  Future<void> refreshMinas(List<DimMina> minas) async {
    await _refreshCatalog(
      table: 'minas',
      items: minas.map((m) => m.toMap()).toList(),
      primaryKeyColumn: 'mina_id',
    );
  }

  Future<void> refreshDimZonas(List<DimZona> zonas) async {
    final db = await _db;
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await _refreshCatalog(
        table: 'zona',
        items: zonas.map((z) => z.toMap()).toList(),
        primaryKeyColumn: 'zona_id',
      );
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> refreshAreas(List<DimArea> areas) async {
    final db = await _db;
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await _refreshCatalog(
        table: 'area',
        items: areas.map((a) => a.toMap()).toList(),
        primaryKeyColumn: 'area_id',
      );
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> refreshFases(List<DimFase> fases) async {
    await _refreshCatalog(
      table: 'fase',
      items: fases.map((f) => f.toMap()).toList(),
      primaryKeyColumn: 'fase_id',
    );
  }

  Future<void> refreshTiposLabor(List<DimTipoLabor> tipos) async {
    await _refreshCatalog(
      table: 'tipo_labor',
      items: tipos.map((t) => t.toMap()).toList(),
      primaryKeyColumn: 'tipo_labor_id',
    );
  }

  Future<void> refreshEstructurasMinerales(
    List<DimEstructuraMineral> estructuras,
  ) async {
    await _refreshCatalog(
      table: 'estructura_mineral',
      items: estructuras.map((e) => e.toMap()).toList(),
      primaryKeyColumn: 'estructura_mineral_id',
    );
  }

  Future<void> refreshNiveles(List<DimNivel> niveles) async {
    await _refreshCatalog(
      table: 'nivel',
      items: niveles.map((n) => n.toMap()).toList(),
      primaryKeyColumn: 'nivel_id',
    );
  }

  Future<void> refreshAlas(List<DimAla> alas) async {
    await _refreshCatalog(
      table: 'ala',
      items: alas.map((a) => a.toMap()).toList(),
      primaryKeyColumn: 'ala_id',
    );
  }

  Future<void> refreshLabores(List<DimLabor> labores) async {
    final db = await _db;
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await _refreshCatalog(
        table: 'labores',
        items: labores.map((l) => l.toMap()).toList(),
        primaryKeyColumn: 'labor_id',
      );
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> refreshDimTurnos(List<DimTurno> turnos) async {
    await _refreshCatalog(
      table: 'dim_turno',
      items: turnos.map((t) => t.toMap()).toList(),
      primaryKeyColumn: 'turno_id',
    );
  }

  Future<void> refreshProcesos(List<Proceso> procesos) async {
    await _refreshCatalog(
      table: 'procesos',
      items: procesos.map((p) => p.toMap()).toList(),
      primaryKeyColumn: 'id',
    );
  }

  Future<void> refreshCargos(List<Cargo> cargos) async {
    await _refreshCatalog(
      table: 'cargos',
      items: cargos.map((c) => c.toMap()).toList(),
      primaryKeyColumn: 'cargo_id',
    );
  }

  Future<void> refreshEstados(List<EstadostBD> estados) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('estados');
      for (final estado in estados) {
        final data = estado.toMap();
        data.remove('id');
        await txn.insert('estados', data);
      }
    });
  }

  Future<void> _refreshCatalog({
    required String table,
    required List<Map<String, dynamic>> items,
    String primaryKeyColumn = 'id',
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      final ids = <int>[];

      for (final item in items) {
        final id = item[primaryKeyColumn];
        if (id is! int) {
          throw ArgumentError(
            'Catalog item for $table is missing a valid $primaryKeyColumn',
          );
        }

        ids.add(id);
        await txn.insert(
          table,
          item,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (ids.isEmpty) {
        await txn.delete(table);
        return;
      }

      final placeholders = List.filled(ids.length, '?').join(', ');
      await txn.delete(
        table,
        where: '$primaryKeyColumn NOT IN ($placeholders)',
        whereArgs: ids,
      );
    });
  }

  Future<HorizontalResolvedEquipoSelection?> resolveEquipoSelection({
    required String nombre,
    required String codigo,
    required String modelo,
  }) async {
    final equipos = await _dbHelper.getEquipos();

    for (final equipo in equipos) {
      if (equipo.nombre == nombre &&
          equipo.codigo == codigo &&
          equipo.modelo == modelo) {
        return HorizontalResolvedEquipoSelection(
          equipo: equipo.nombre,
          codigo: equipo.codigo,
          modelo: equipo.modelo,
          equipoId: equipo.id,
        );
      }
    }

    return null;
  }

  Future<Zona?> resolveZonaByNombre(String nombre, {String? proceso}) async {
    final zonas = proceso == null
        ? await _dbHelper.getZonas()
        : await _dbHelper.getZonasByProceso(proceso);

    for (final zona in zonas) {
      if (zona.nombre == nombre) {
        return zona;
      }
    }

    return null;
  }

  Future<JefeGuardia?> resolveJefeGuardiaByFullName(String fullName) async {
    final jefes = await _dbHelper.getJefesGuardia();
    final normalizedFullName = fullName.trim();

    for (final jefe in jefes) {
      final jefeFullName = '${jefe.nombres} ${jefe.apellidos}'.trim();
      if (jefeFullName == normalizedFullName) {
        return jefe;
      }
    }

    return null;
  }
}
