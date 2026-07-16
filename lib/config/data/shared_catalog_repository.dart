import 'dart:convert';

import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/DimAla.dart';
import 'package:i_miner/models/DimArea.dart';
import 'package:i_miner/models/DimEstructuraMineral.dart';
import 'package:i_miner/models/DimFase.dart';
import 'package:i_miner/models/DimLabor.dart';
import 'package:i_miner/models/DimMina.dart';
import 'package:i_miner/models/DimNivel.dart';
import 'package:i_miner/models/DimPeriodo.dart';
import 'package:i_miner/models/DimTipoLabor.dart';
import 'package:i_miner/models/DimTurno.dart';
import 'package:i_miner/models/DimZona.dart';
import 'package:i_miner/models/Equipo.dart';
import 'package:i_miner/models/guardia.dart';
import 'package:i_miner/models/JefeGuardia.dart';
import 'package:i_miner/models/malla.dart';
import 'package:i_miner/models/perno.dart';
import 'package:i_miner/models/plan_avance_th.dart';
import 'package:i_miner/models/plan_metraje_tl.dart';
import 'package:i_miner/models/plan_produccion.dart';
import 'package:i_miner/models/TipoPerforacion.dart';
import 'package:i_miner/models/zona.dart';

class SharedCatalogRepository {
  SharedCatalogRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  Future<List<Perno>> getPernos() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query(
      'pernos',
      orderBy: 'tipo_perno ASC, longitud ASC',
    );

    return maps.map(Perno.fromJson).toList();
  }

  Future<List<Malla>> getMallas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('mallas', orderBy: 'tipo_malla ASC');

    return maps.map(Malla.fromJson).toList();
  }

  Future<List<DimLabor>> getLabores() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('labores', orderBy: 'nombre_labor ASC');

    return maps.map(DimLabor.fromJson).toList();
  }

  Future<List<DimMina>> getMinas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('minas', orderBy: 'nombre ASC');

    return maps.map(DimMina.fromJson).toList();
  }

  Future<List<DimZona>> getZonas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('zona', orderBy: 'nombre ASC');

    return maps.map(DimZona.fromJson).toList();
  }

  Future<List<DimArea>> getAreas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('area', orderBy: 'nombre ASC');

    return maps.map(DimArea.fromJson).toList();
  }

  Future<List<DimFase>> getFases() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('fase', orderBy: 'nombre ASC');

    return maps.map(DimFase.fromJson).toList();
  }

  Future<List<DimTipoLabor>> getTiposLabor() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('tipo_labor', orderBy: 'nombre ASC');

    return maps.map(DimTipoLabor.fromJson).toList();
  }

  Future<List<DimEstructuraMineral>> getEstructurasMinerales() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('estructura_mineral', orderBy: 'nombre ASC');

    return maps.map(DimEstructuraMineral.fromJson).toList();
  }

  Future<List<DimNivel>> getNiveles() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('nivel', orderBy: 'nombre ASC');

    return maps.map(DimNivel.fromJson).toList();
  }

  Future<List<DimAla>> getAlas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('ala', orderBy: 'orden ASC, nombre ASC');

    return maps.map(DimAla.fromJson).toList();
  }

  // ============================================================
  // Equipos
  // ============================================================

  Future<List<Equipo>> getEquipos() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('Equipo');
    return List.generate(maps.length, (i) => Equipo.fromJson(maps[i]));
  }

  Future<Equipo?> getEquipoById(int equipoId) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query(
      'Equipo',
      where: 'id = ?',
      whereArgs: [equipoId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Equipo.fromJson(maps.first);
  }

  Future<Map<String, dynamic>?> getEquipoUltimosHorometros(int equipoId) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query(
      'Equipo',
      columns: ['ultimos_horometros'],
      where: 'id = ?',
      whereArgs: [equipoId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final raw = maps.first['ultimos_horometros'];
    if (raw == null) return null;
    try {
      if (raw is Map) return Map<String, dynamic>.from(raw);
      final decoded = jsonDecode(raw.toString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  Future<void> updateEquipoUltimosHorometros(
    int equipoId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    await db.update(
      'Equipo',
      {'ultimos_horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [equipoId],
    );
  }

  // ============================================================
  // Guardias y Jefes de Guardia
  // ============================================================

  Future<List<Guardia>> getGuardias() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('Guardia');
    return List.generate(maps.length, (i) => Guardia.fromJson(maps[i]));
  }

  Future<List<JefeGuardia>> getJefesGuardia() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'jefe_guardias',
      orderBy: 'apellidos ASC, nombres ASC',
    );
    return List.generate(maps.length, (i) => JefeGuardia.fromJson(maps[i]));
  }

  Future<List<String>> getJefesGuardiaNombres() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    try {
      final result = await db.query(
        'jefe_guardias',
        columns: ['nombres', 'apellidos'],
        orderBy: 'apellidos ASC, nombres ASC',
      );
      return result.map((row) {
        final nombres = row['nombres'] as String? ?? '';
        final apellidos = row['apellidos'] as String? ?? '';
        return '$nombres $apellidos'.trim();
      }).toList();
    } catch (e) {
      print("Error al obtener nombres de jefes de guardia: $e");
      return [];
    }
  }

  // ============================================================
  // Periodos
  // ============================================================

  Future<List<DimPeriodo>> getPeriodos() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query(
      'dim_periodo',
      orderBy: 'anno DESC, numero DESC',
    );
    return List.generate(maps.length, (i) => DimPeriodo.fromJson(maps[i]));
  }

  Future<DimPeriodo?> getPeriodoVigente({
    DateTime? forDate,
    String? tipo,
  }) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final targetDate = (forDate ?? DateTime.now())
        .toIso8601String()
        .split('T')
        .first;
    final whereClause = StringBuffer('fecha_inicio <= ? AND fecha_fin >= ?');
    final whereArgs = <Object>[targetDate, targetDate];
    if (tipo != null && tipo.isNotEmpty) {
      whereClause.write(' AND tipo = ?');
      whereArgs.add(tipo);
    }
    final maps = await db.query(
      'dim_periodo',
      where: whereClause.toString(),
      whereArgs: whereArgs,
      orderBy: 'anno DESC, numero DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DimPeriodo.fromJson(maps.first);
  }

  // ============================================================
  // Turnos
  // ============================================================

  Future<List<DimTurno>> getDimTurnos() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('dim_turno', orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => DimTurno.fromJson(maps[i]));
  }

  // ============================================================
  // Zonas (Zona model, not DimZona)
  // ============================================================

  /// Returns full Zona model (includes proceso, minaNombre, timestamps).
  /// Use instead of getZonas() (which returns DimZona) when you need the
  /// richer model with proceso/relationship info.
  Future<List<Zona>> getZonasAsZona() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('zona');
    return List.generate(maps.length, (i) => Zona.fromJson(maps[i]));
  }

  Future<List<Zona>> getZonasByProceso(String proceso) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'zona',
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Zona.fromJson(maps[i]));
  }

  // ============================================================
  // Procesos
  // ============================================================

  Future<List<Map<String, dynamic>>> getProcesos() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    return await db.query('procesos', orderBy: 'nombre ASC');
  }

  Future<Map<String, dynamic>?> getProcesoById(int id) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final rows = await db.query(
      'procesos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<Map<String, dynamic>>> getDestinosByProcesoId(
    int procesoId,
  ) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    return await db.query(
      'origen_destino',
      where: 'proceso_id = ?',
      whereArgs: [procesoId],
      orderBy: 'nombre ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getOrigenDestinoByProcesoAndTipo({
    required String proceso,
    required String tipo,
  }) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    return await db.query(
      'origen_destino',
      where: 'UPPER(TRIM(proceso)) = ? AND UPPER(TRIM(tipo)) = ?',
      whereArgs: [proceso.trim().toUpperCase(), tipo.trim().toUpperCase()],
      orderBy: 'nombre ASC',
    );
  }

  // ============================================================
  // Tipos de Perforación
  // ============================================================

  Future<List<TipoPerforacion>> getTiposPerforacionByProcesoId(
    int procesoId,
  ) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'tipo_perforaciones',
      where: 'proceso_id = ?',
      whereArgs: [procesoId],
    );
    return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
  }

  Future<List<TipoPerforacion>> getTiposPerforacion() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'tipo_perforaciones',
    );
    return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
  }

  Future<List<TipoPerforacion>> getTiposPerforacionhorizontalfil() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'tipo_perforaciones',
      where: 'proceso = ? AND permitido_medicion = ?',
      whereArgs: ['PERFORACIÓN HORIZONTAL', 1],
    );
    return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
  }

  Future<List<TipoPerforacion>> getTiposPerforacionLargofil() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'tipo_perforaciones',
      where: 'proceso = ? AND permitido_medicion = ?',
      whereArgs: ['PERFORACIÓN TALADROS LARGOS', 1],
    );
    return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
  }

  // ============================================================
  // Planes
  // ============================================================

  Future<List<PlanMetrajeTL>> getPlanesMetrajeTL() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('PlanMetrajeTL');
    return List.generate(maps.length, (i) => PlanMetrajeTL.fromJson(maps[i]));
  }

  Future<List<PlanAvanceTH>> getPlanesAvanceTH() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'planes_metrajes_avances',
    );
    return List.generate(maps.length, (i) => PlanAvanceTH.fromJson(maps[i]));
  }

  Future<List<PlanProduccion>> getPlanesProduccion() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('planes_produccion');
    return List.generate(maps.length, (i) => PlanProduccion.fromJson(maps[i]));
  }

  // ============================================================
  // Estados y Categorías
  // ============================================================

  Future<List<Map<String, dynamic>>> getEstadosByProcesoAndCategoria(
    int procesoId,
    int categoriaId, {
    String? tipoEquipo,
  }) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final normalizedTipoEquipo = tipoEquipo?.trim().toUpperCase();
    return await db.query(
      'estados',
      where: normalizedTipoEquipo == null || normalizedTipoEquipo.isEmpty
          ? 'proceso_id = ? AND categoria_id = ?'
          : 'proceso_id = ? AND categoria_id = ? AND UPPER(TRIM(tipo_equipo)) = ?',
      whereArgs: normalizedTipoEquipo == null || normalizedTipoEquipo.isEmpty
          ? [procesoId, categoriaId]
          : [procesoId, categoriaId, normalizedTipoEquipo],
      orderBy: 'codigo ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getCategoriasEstados() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    return await db.query(
      'categorias_estados',
      where: 'activo = 1',
      orderBy: 'nombre ASC',
    );
  }

  // ============================================================
  // Longitud de Barras
  // ============================================================

  Future<List<Map<String, dynamic>>> getLongitudBarrasPorProceso(
    String proceso,
  ) async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    return await db.query(
      'longitud_barras',
      where: 'proceso = ?',
      whereArgs: [proceso],
    );
  }
}
