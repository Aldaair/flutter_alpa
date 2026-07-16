import 'dart:convert';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class OperationRepository {
  OperationRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  Future<Database> get _db async => _databaseHelper.database;

  // ============================================================
  // Generic CRUD
  // ============================================================

  Future<Map<String, dynamic>?> querySingle(
    String tableName,
    int id, {
    List<String>? columns,
  }) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      columns: columns,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<int> insert(String tableName, Map<String, dynamic> data) async {
    final db = await _db;
    return db.insert(tableName, data);
  }

  Future<bool> update(
    String tableName,
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await _db;
    final updated = await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated > 0;
  }

  Future<bool> delete(String tableName, int id) async {
    final db = await _db;
    final deleted = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return deleted > 0;
  }

  // ============================================================
  // Shared Defaults for JSON fields
  // ============================================================

  Map<String, dynamic> defaultControlLlantas() {
    return {'numero1': true, 'numero2': true, 'numero3': true, 'numero4': true};
  }

  /// Returns default horometros structure based on process type.
  /// Most drilling processes use diesel/electrico/percusion.
  /// Carguio/Dumper/Acarreo use a single 'horometro' key.
  Map<String, dynamic> defaultHorometros(String processType) {
    if (processType == 'Carguio' ||
        processType == 'Dumper' ||
        processType == 'Acarreo') {
      return {
        'horometro': {'inicio': 0, 'final': 0, 'op': true},
      };
    }
    return {
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
      'electrico': {'inicio': 0, 'final': 0, 'op': true},
      'percusion': {'inicio': 0, 'final': 0, 'op': true},
    };
  }

  Map<String, dynamic> defaultCondicionesEquipo() {
    return {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };
  }

  // ============================================================
  // Control de Llantas
  // ============================================================

  Future<Map<String, dynamic>> getControlLlantasFromTable(
    String tableName,
    int operacionId,
  ) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['control_llantas'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return defaultControlLlantas();
    final controlJson = result.first['control_llantas'] as String? ?? '{}';
    try {
      final control = jsonDecode(controlJson);
      if (control is Map<String, dynamic>) {
        return {...defaultControlLlantas(), ...control};
      }
      if (control is Map) {
        return {
          ...defaultControlLlantas(),
          ...control.map((key, value) => MapEntry(key.toString(), value)),
        };
      }
      return defaultControlLlantas();
    } catch (e) {
      print('Error decodificando control de llantas: $e');
      return defaultControlLlantas();
    }
  }

  // ============================================================
  // Metadata CRUD (generic with tableName)
  // ============================================================

  Future<List<Map<String, dynamic>>> getCheckList(
    int operacionId, {
    required String tableName,
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return [];
    final checkListJson = result.first['check_list'] as String? ?? '[]';
    try {
      final lista = jsonDecode(checkListJson) as List<dynamic>;
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  Future<bool> updateCheckList(
    int operacionId,
    List<Map<String, dynamic>> checkList, {
    required String tableName,
  }) async {
    final db = await _db;
    final updated = await db.update(
      tableName,
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    return updated > 0;
  }

  Future<Map<String, dynamic>> getHorometros(
    int operacionId, {
    required String tableName,
    Map<String, dynamic> Function()? defaultFactory,
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) {
      return defaultFactory != null
          ? defaultFactory()
          : defaultHorometros('TalLargo');
    }
    final horometrosJson = result.first['horometros'] as String? ?? '{}';
    try {
      final horometros = jsonDecode(horometrosJson) as Map<String, dynamic>;
      if (horometros.isEmpty && defaultFactory != null) return defaultFactory();
      // Migration-safe: ensure all default keys exist in stored data
      if (defaultFactory != null) {
        final defaults = defaultFactory();
        defaults.forEach((key, value) {
          horometros.putIfAbsent(key, () => value);
        });
      }
      return horometros;
    } catch (e) {
      print('Error decodificando horometros: $e');
      return defaultFactory != null
          ? defaultFactory()
          : defaultHorometros('TalLargo');
    }
  }

  Future<bool> updateHorometros(
    int operacionId,
    Map<String, dynamic> horometros, {
    required String tableName,
  }) async {
    final db = await _db;
    final updated = await db.update(
      tableName,
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    return updated > 0;
  }

  Future<Map<String, dynamic>> getCondicionesEquipo(
    int operacionId, {
    required String tableName,
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return defaultCondicionesEquipo();
    final condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';
    try {
      final condiciones = jsonDecode(condicionesJson) as Map<String, dynamic>;
      condiciones.putIfAbsent('horaLlenado', () => '');
      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultCondicionesEquipo();
    }
  }

  Future<bool> updateCondicionesEquipo(
    int operacionId,
    Map<String, dynamic> condiciones, {
    required String tableName,
  }) async {
    final db = await _db;
    final updated = await db.update(
      tableName,
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    return updated > 0;
  }

  Future<Map<String, dynamic>> getControlLlantas(
    int operacionId, {
    required String tableName,
  }) async {
    return getControlLlantasFromTable(tableName, operacionId);
  }

  Future<bool> updateControlLlantas(
    int operacionId,
    Map<String, dynamic> controlLlantas, {
    required String tableName,
  }) async {
    final db = await _db;
    final updated = await db.update(
      tableName,
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    return updated > 0;
  }

  // ============================================================
  // Estados CRUD (generic with tableName)
  // ============================================================

  Future<List<Map<String, dynamic>>> getEstadosByOperacionId(
    int operacionId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return [];
    final registrosJson = result.first['registros'] as String? ?? '[]';
    final registros = jsonDecode(registrosJson) as List<dynamic>;
    return registros.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<bool> updateHoraFinal(
    int operacionId,
    int estadoId,
    String horaFinal, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return false;
    final registrosJson = result.first['registros'] as String? ?? '[]';
    final registros = jsonDecode(registrosJson) as List<dynamic>;
    bool encontrado = false;
    String tipoEstado = '';
    for (var i = 0; i < registros.length; i++) {
      if (registros[i]['id'].toString() == estadoId.toString()) {
        tipoEstado = registros[i]['estado'] as String;
        registros[i]['hora_final'] = horaFinal;
        encontrado = true;
        break;
      }
    }
    if (!encontrado) {
      print('Warning: Estado no encontrado en JSON');
      return false;
    }
    final updated = await db.update(
      tableName,
      {'registros': jsonEncode(registros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    print('Hora final actualizada para estado $tipoEstado: $horaFinal');
    return updated > 0;
  }

  Future<Map<String, dynamic>?> createEstado(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>? operacion,
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return null;
    final registrosJson = result.first['registros'] as String? ?? '[]';
    final registros = jsonDecode(registrosJson) as List<dynamic>;
    int nuevoNumero = 1;
    if (registros.isNotEmpty) {
      final ultimoNumero = registros.last['numero'] ?? 0;
      nuevoNumero = (ultimoNumero as int) + 1;
    }
    final nuevoEstado = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch + registros.length,
      'numero': nuevoNumero,
      'estado': estado,
      'codigo': codigo,
      'hora_inicio': horaInicio,
      'hora_final': horaFinal ?? '',
      'operacion': operacion ?? <String, dynamic>{},
    };
    registros.add(nuevoEstado);
    await db.update(
      tableName,
      {'registros': jsonEncode(registros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    return Map<String, dynamic>.from(nuevoEstado);
  }

  Future<bool> updateEstado(
    int operacionId,
    int estadoId,
    Map<String, dynamic>? estado, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return false;
    final registrosJson = result.first['registros'] as String? ?? '[]';
    final registros = jsonDecode(registrosJson) as List<dynamic>;
    bool encontrado = false;
    for (var i = 0; i < registros.length; i++) {
      if (registros[i]['id'] == estadoId) {
        if (estado != null) {
          registros[i]['estado'] = estado['estado'] ?? registros[i]['estado'];
          registros[i]['codigo'] = estado['codigo'] ?? registros[i]['codigo'];
          registros[i]['hora_inicio'] =
              estado['hora_inicio'] ?? registros[i]['hora_inicio'];
          registros[i]['hora_final'] =
              estado['hora_final'] ?? registros[i]['hora_final'];
        }
        encontrado = true;
        break;
      }
    }
    if (!encontrado) return false;
    final updated = await db.update(
      tableName,
      {'registros': jsonEncode(registros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    return updated > 0;
  }

  Future<bool> deleteEstado(
    int operacionId,
    int estadoId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return false;
    final registrosJson = result.first['registros'] as String? ?? '[]';
    final registros = jsonDecode(registrosJson) as List<dynamic>;
    if (registros.isEmpty) return false;
    final lista = registros.map((e) => Map<String, dynamic>.from(e)).toList();
    lista.sort((a, b) => (a['numero'] ?? 0).compareTo(b['numero'] ?? 0));
    Map<String, dynamic>? estadoAEliminar;
    for (var e in lista) {
      if (e['id'] == estadoId) {
        estadoAEliminar = e;
        break;
      }
    }
    if (estadoAEliminar == null) return false;
    final numeroEliminar = estadoAEliminar['numero'] as int? ?? 0;
    final nuevosRegistros = <Map<String, dynamic>>[];
    for (var e in lista) {
      final numero = e['numero'] as int? ?? 0;
      if (numero < numeroEliminar) {
        nuevosRegistros.add(e);
      }
    }
    for (int i = 0; i < nuevosRegistros.length; i++) {
      nuevosRegistros[i]['numero'] = i + 1;
    }
    for (int i = 0; i < nuevosRegistros.length; i++) {
      if (i < nuevosRegistros.length - 1) {
        nuevosRegistros[i]['hora_final'] =
            nuevosRegistros[i + 1]['hora_inicio'] ?? '';
      } else {
        nuevosRegistros[i]['hora_final'] = '';
      }
    }
    final updated = await db.update(
      tableName,
      {'registros': jsonEncode(nuevosRegistros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    return updated > 0;
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionId(
    int operacionId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return null;
    final registrosJson = result.first['registros'] as String? ?? '[]';
    try {
      final registros = jsonDecode(registrosJson) as List<dynamic>;
      if (registros.isEmpty) return null;
      return Map<String, dynamic>.from(registros.last);
    } catch (e) {
      print('Error obteniendo ultimo estado: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createReservaEstado(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return null;
    final registrosJson = result.first['registros'] as String? ?? '[]';
    final registros = jsonDecode(registrosJson) as List<dynamic>;
    final nuevoId = DateTime.now().millisecondsSinceEpoch + registros.length;
    final nuevoEstado = <String, dynamic>{
      'id': nuevoId,
      'numero': numero,
      'estado': 'RESERVA',
      'codigo': '401',
      'hora_inicio': horaInicio,
      'hora_final': horaFinal,
      'operacion': <String, dynamic>{},
    };
    registros.add(nuevoEstado);
    await db.update(
      tableName,
      {'registros': jsonEncode(registros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    return nuevoEstado;
  }

  Future<Map<String, dynamic>?> getOperacionByEstadoId(
    int operacionId,
    int estadoId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) {
      return _defaultOperacionByEstado();
    }
    final registrosJson = result.first['registros'] as String? ?? '[]';
    try {
      final registros = jsonDecode(registrosJson) as List<dynamic>;
      final estadoEncontrado = registros.firstWhere(
        (estado) => estado['id'] == estadoId,
        orElse: () => null,
      );
      if (estadoEncontrado != null &&
          estadoEncontrado.containsKey('operacion')) {
        return estadoEncontrado['operacion'] as Map<String, dynamic>;
      }
      return _defaultOperacionByEstado();
    } catch (e) {
      print('Error decodificando registros: $e');
      return _defaultOperacionByEstado();
    }
  }

  Map<String, dynamic> _defaultOperacionByEstado() {
    return {
      'nivel': '',
      'tipo_labor': '',
      'labor': '',
      'ala': '',
      'n_taladros_produccion': '',
      'metros_perforados_produccion': '',
      'n_taladros_rimados': '',
      'metros_perforados_rimados': '',
      'n_taladros_alivio': '',
      'metros_perforados_alivio': '',
      'n_taladros_repaso': '',
      'metros_perforados_repaso': '',
      'long_barras': '',
      'num_barras': '',
      'tipo_perforacion': '',
      'observaciones': '',
    };
  }

  Future<bool> updateOperacionByEstadoId(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );
    if (result.isEmpty) return false;
    final registrosJson = result.first['registros'] as String? ?? '[]';
    try {
      final registros = jsonDecode(registrosJson) as List<dynamic>;
      bool encontrado = false;
      for (var i = 0; i < registros.length; i++) {
        if (registros[i]['id'] == estadoId) {
          registros[i]['operacion'] = operacionData;
          encontrado = true;
          break;
        }
      }
      if (!encontrado) {
        print('Warning: Estado no encontrado en JSON');
        return false;
      }
      final updateData = <String, dynamic>{'registros': jsonEncode(registros)};
      updateData.addAll(await _buildOperationHeaderUpdateData(operacionData));
      final updated = await db.update(
        tableName,
        updateData,
        where: 'id = ?',
        whereArgs: [operacionId],
      );
      return updated > 0;
    } catch (e) {
      print('Error actualizando datos de perforacion: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _buildOperationHeaderUpdateData(
    Map<String, dynamic>? operacionData,
  ) async {
    if (operacionData == null || operacionData.isEmpty) {
      return <String, dynamic>{};
    }
    final updateData = <String, dynamic>{};
    final laborId = _asInt(operacionData['labor_id']);
    if (laborId != null) updateData['labor_id'] = laborId;
    final frenteOrigen =
        operacionData['frente_origen']?.toString().trim() ?? '';
    if (frenteOrigen.isNotEmpty) updateData['frente_origen'] = frenteOrigen;
    final labor = operacionData['labor']?.toString().trim() ?? '';
    if (labor.isNotEmpty) updateData['labor'] = labor;
    final ala = operacionData['ala']?.toString().trim() ?? '';
    if (ala.isNotEmpty) updateData['ala'] = ala;
    final alaId = await _resolveAlaId(
      operacionData['ala_id'],
      operacionData['ala'],
    );
    if (alaId != null) updateData['ala_id'] = alaId;
    return updateData;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<int?> _resolveAlaId(dynamic rawAlaId, dynamic rawAla) async {
    final alaId = _asInt(rawAlaId);
    if (alaId != null) return alaId;
    final ala = rawAla?.toString().trim() ?? '';
    if (ala.isEmpty) return null;
    try {
      final db = await _db;
      final rows = await db.query(
        'alas',
        columns: ['ala_id'],
        where: 'nombre = ?',
        whereArgs: [ala],
        limit: 1,
      );
      if (rows.isNotEmpty) return rows.first['ala_id'] as int?;
    } catch (_) {}
    return null;
  }

  // ============================================================
  // Query Helpers
  // ============================================================

  Future<void> cerrarOperacion(
    int operacionId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await _db;
    await db.update(
      tableName,
      {'cerrado': 1},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
  }

  Future<List<Map<String, dynamic>>> queryAndHydrateOperations(
    String tableName,
    int turnoId,
    String fecha, {
    int? operadorId,
    bool onlyActive = false,
  }) async {
    final db = await _db;
    late final String where;
    late final List<dynamic> whereArgs;
    if (onlyActive) {
      where = operadorId != null
          ? 'turno_id = ? AND fecha = ? AND operador_id = ? AND cerrado = ?'
          : 'turno_id = ? AND fecha = ? AND cerrado = ?';
      whereArgs = operadorId != null
          ? [turnoId, fecha, operadorId, 0]
          : [turnoId, fecha, 0];
    } else {
      where = operadorId != null
          ? 'turno_id = ? AND fecha = ? AND operador_id = ?'
          : 'turno_id = ? AND fecha = ?';
      whereArgs = operadorId != null
          ? [turnoId, fecha, operadorId]
          : [turnoId, fecha];
    }
    final rows = await db.query(tableName, where: where, whereArgs: whereArgs);
    return normalizeOperationRows(rows);
  }

  List<Map<String, dynamic>> normalizeOperationRows(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return rows;
    return rows.map((row) {
      final normalized = Map<String, dynamic>.from(row);
      final cerrado = _asInt(row['cerrado']) ?? 0;
      final enviado = _asInt(row['enviado']) ?? 0;
      normalized['estado'] = cerrado == 1 ? 'cerrado' : 'activo';
      normalized['envio'] = enviado;
      normalized['registrador_usuario_id'] = row['registrador_id'];
      normalized['registrador_nombre'] = row['registrador'];
      normalized['jefeGuardia'] = row['jefe_guardia'];
      return normalized;
    }).toList();
  }

  void appendHybridOperationMetadata(
    Map<String, dynamic> insertData, {
    int? turnoId,
    String? frenteOrigen,
    int? registradorId,
    int? registradorUsuarioId,
    String? registrador,
    String? registradorNombre,
    int? laborId,
    String? labor,
    String? ala,
    int? alaId,
  }) {
    final resolvedRegistradorId = registradorId ?? registradorUsuarioId;
    final resolvedRegistrador = registrador ?? registradorNombre;
    if (turnoId != null) insertData['turno_id'] = turnoId;
    if (frenteOrigen != null && frenteOrigen.trim().isNotEmpty) {
      insertData['frente_origen'] = frenteOrigen.trim();
    }
    if (resolvedRegistradorId != null) {
      insertData['registrador_id'] = resolvedRegistradorId;
    }
    if (laborId != null) insertData['labor_id'] = laborId;
    if (labor != null && labor.trim().isNotEmpty) {
      insertData['labor'] = labor.trim();
    }
    if (resolvedRegistrador != null && resolvedRegistrador.trim().isNotEmpty) {
      insertData['registrador'] = resolvedRegistrador.trim();
    }
    if (ala != null && ala.trim().isNotEmpty) {
      insertData['ala'] = ala.trim();
    }
    if (alaId != null) {
      insertData['ala_id'] = alaId;
    }
  }

  // ============================================================
  // INSERT Helpers
  // ============================================================

  /// Build horometros JSON from defaults, applying base values if present.
  Map<String, dynamic> _buildHorometrosJson(
    Map<String, dynamic> defaultHorometros,
    List<Map<String, dynamic>>? horometrosBase,
  ) {
    final result = Map<String, dynamic>.from(defaultHorometros);
    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      for (var item in horometrosBase) {
        final tipo = item['tipo_horometro'] as String?;
        if (tipo == null) continue;
        final finalValor = (item['final'] ?? 0).toDouble();
        if (result.containsKey(tipo) && result[tipo] is Map) {
          result[tipo] = {
            ...Map<String, dynamic>.from(result[tipo] as Map),
            'inicio': finalValor,
          };
        }
      }
    }
    return result;
  }

  /// Build the common base insertData map with horometros, condiciones,
  /// check_list, and control_llantas pre-filled.
  Map<String, dynamic> _buildOperationInsertBase({
    required String fecha,
    required String turno,
    required String operador,
    required String jefeGuardia,
    required String equipo,
    required Map<String, dynamic> horometrosJson,
    List<Map<String, dynamic>>? checkListJson,
    String? nEquipo,
    String? capacidad,
    String? tipoEquipo,
  }) {
    final condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    final controlLlantasJson = defaultControlLlantas();
    final checkListStr = jsonEncode(checkListJson ?? []);

    final data = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'check_list': checkListStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };

    if (nEquipo != null) data['n_equipo'] = nEquipo;
    if (capacidad != null) data['capacidad'] = capacidad;
    if (tipoEquipo != null) data['tipo_equipo'] = tipoEquipo;

    return data;
  }

  // ============================================================
  // Per-Process INSERT Methods
  // ============================================================

  Future<int> insertOperacionTalLargo(
    String fecha, {
    String? turno,
    String? operador,
    String? jefeGuardia,
    String? equipo,
    String? registradorNombre,
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    int? registradorUsuarioId,
    int? laborId,
    String? labor,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson(
      defaultHorometros('TalLargo'),
      horometrosBase,
    );
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno ?? '',
      operador: operador ?? '',
      jefeGuardia: jefeGuardia ?? '',
      equipo: equipo ?? '',
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_tal_largo', data);
  }

  Future<int> insertOperacionTalHorizontal(
    String fecha,
    String turno,
    String operador,
    String jefeGuardia,
    String equipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson(
      defaultHorometros('TalLargo'),
      horometrosBase,
    );
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno,
      operador: operador,
      jefeGuardia: jefeGuardia,
      equipo: equipo,
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (zonaId != null) data['zona_id'] = zonaId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_tal_horizontal', data);
  }

  Future<int> insertOperacionEmpernador(
    String fecha,
    String turno,
    String seccion,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo,
    String tipoEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson({
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
      'electrico': {'inicio': 0, 'final': 0, 'op': true},
      'percusion': {'inicio': 0, 'final': 0, 'op': true},
      'empernador': {'inicio': 0, 'final': 0, 'op': true},
    }, horometrosBase);
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno,
      operador: operador,
      jefeGuardia: jefeGuardia,
      equipo: equipo,
      nEquipo: nEquipo,
      tipoEquipo: tipoEquipo,
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    data['seccion'] = seccion;
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (zonaId != null) data['zona_id'] = zonaId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_empernador', data);
  }

  Future<int> insertOperacionCarguio(
    String fecha,
    String turno,
    String seccion,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo,
    String capacidad,
    String tipoEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? checkListTelemandoJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson({
      'horometro': {'inicio': 0, 'final': 0, 'op': true},
    }, horometrosBase);
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno,
      operador: operador,
      jefeGuardia: jefeGuardia,
      equipo: equipo,
      nEquipo: nEquipo,
      capacidad: capacidad,
      tipoEquipo: tipoEquipo,
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    data['seccion'] = seccion;
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (zonaId != null) data['zona_id'] = zonaId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    const programaTrabajoJson = {
      'n_cucharas_programado': 0,
      'n_cucharas_realizado': 0,
    };
    data['programa_trabajo'] = jsonEncode(programaTrabajoJson);
    data['check_list_telemando'] = jsonEncode(checkListTelemandoJson ?? []);
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_carguio', data);
  }

  Future<int> insertOperacionDumper(
    String fecha,
    String turno,
    String seccion,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo,
    String capacidad,
    String tipoEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? checkListTelemandoJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson({
      'horometro': {'inicio': 0, 'final': 0, 'op': true},
    }, horometrosBase);
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno,
      operador: operador,
      jefeGuardia: jefeGuardia,
      equipo: equipo,
      nEquipo: nEquipo,
      capacidad: capacidad,
      tipoEquipo: tipoEquipo,
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    data['seccion'] = seccion;
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (zonaId != null) data['zona_id'] = zonaId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    const programaTrabajoJson = {
      'n_cucharas_programado': 0,
      'n_cucharas_realizado': 0,
    };
    data['programa_trabajo'] = jsonEncode(programaTrabajoJson);
    data['check_list_telemando'] = jsonEncode(checkListTelemandoJson ?? []);
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_Dumper', data);
  }

  Future<int> insertOperacionAcarreo(
    String fecha,
    String turno,
    String seccion,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo,
    String capacidad,
    String tipoEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? checkListTelemandoJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
    int? revisado,
    int? aprobacion,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson({
      'horometro': {'inicio': 0, 'final': 0, 'op': true},
    }, horometrosBase);
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno,
      operador: operador,
      jefeGuardia: jefeGuardia,
      equipo: equipo,
      nEquipo: nEquipo,
      capacidad: capacidad,
      tipoEquipo: tipoEquipo,
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    data['seccion'] = seccion;
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (zonaId != null) data['zona_id'] = zonaId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    if (revisado != null) data['revisado'] = revisado;
    if (aprobacion != null) data['aprobacion'] = aprobacion;
    const programaTrabajoJson = {
      'n_viaje_mineral': 0.0,
      'n_viaje_desmonte': 0.0,
      'programado': 0.0,
      'realizado': 0.0,
      'total': 0.0,
    };
    data['programa_trabajo'] = jsonEncode(programaTrabajoJson);
    data['check_list_telemando'] = jsonEncode(checkListTelemandoJson ?? []);
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_acarreo', data);
  }

  Future<int> insertOperacionRompeBaco(
    String fecha,
    String turno,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson({
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
      'percusion': {'inicio': 0, 'final': 0, 'op': true},
    }, horometrosBase);
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno,
      operador: operador,
      jefeGuardia: jefeGuardia,
      equipo: equipo,
      nEquipo: nEquipo,
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (zonaId != null) data['zona_id'] = zonaId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_rompe_baco', data);
  }

  Future<int> insertOperacionScalamin(
    String fecha,
    String turno,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson({
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
      'percusion': {'inicio': 0, 'final': 0, 'op': true},
    }, horometrosBase);
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno,
      operador: operador,
      jefeGuardia: jefeGuardia,
      equipo: equipo,
      nEquipo: nEquipo,
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (zonaId != null) data['zona_id'] = zonaId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_scalamin', data);
  }

  Future<int> insertOperacionScissor(
    String fecha,
    String turno,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson({
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
    }, horometrosBase);
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno,
      operador: operador,
      jefeGuardia: jefeGuardia,
      equipo: equipo,
      nEquipo: nEquipo,
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (zonaId != null) data['zona_id'] = zonaId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_scissor', data);
  }

  Future<int> insertOperacionAnfochanger(
    String fecha,
    String turno,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await _db;
    final horometrosJson = _buildHorometrosJson({
      'horometro_principal': {'inicio': 0, 'final': 0, 'op': true},
      'electrico': {'inicio': 0, 'final': 0, 'op': true},
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
    }, horometrosBase);
    final data = _buildOperationInsertBase(
      fecha: fecha,
      turno: turno,
      operador: operador,
      jefeGuardia: jefeGuardia,
      equipo: equipo,
      nEquipo: nEquipo,
      horometrosJson: horometrosJson,
      checkListJson: checkListJson,
    );
    if (operadorId != null) data['operador_id'] = operadorId;
    if (equipoId != null) data['equipo_id'] = equipoId;
    if (zonaId != null) data['zona_id'] = zonaId;
    if (jefeGuardiaId != null) data['jefe_guardia_id'] = jefeGuardiaId;
    appendHybridOperationMetadata(
      data,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_anfochanger', data);
  }

  // ============================================================
  // Generic DELETE
  // ============================================================

  /// Delete an operation by id from the given table.
  /// Returns the number of rows deleted.
  Future<int> deleteOperation(String tableName, int id) async {
    final db = await _db;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
