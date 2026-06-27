import 'dart:convert';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/api/v2/operation_dtos.dart';

class ExportarService {
  final DatabaseHelper dbHelper;

  ExportarService(this.dbHelper);

  Future<List<Map<String, dynamic>>> prepararDatosParaExportar(
    String tipo,
    Set<int> selectedItems,
    List<Map<String, dynamic>> operacionData,
  ) async {
    final List<Map<String, dynamic>> results = [];

    for (var id in selectedItems) {
      final op = operacionData.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (op.isEmpty) continue;

      final map = _buildOperationMap(tipo, op, id);
      results.add(map);
    }

    return results;
  }

  Map<String, dynamic> _buildOperationMap(
    String tipo,
    Map<String, dynamic> op,
    int localId,
  ) {
    final dto = _buildDto(tipo, op);
    final map = dto.toJson();
    map['local_id'] = localId;
    return map;
  }

  OperacionUpsertRequest _buildDto(String tipo, Map<String, dynamic> op) {
    final enviado = op['enviado'] ?? op['envio'] ?? 0;
    final estadoOperacion = (op['cerrado'] ?? 0) == 1
        ? 'cerrado'
        : (op['estado'] ?? 'activo');
    final horometrosRaw = _decodeMap(op['horometros']);
    final horometros = horometrosRaw.isNotEmpty
        ? HorometrosRequest(horometrosRaw)
        : null;
    final condicionesRaw = _decodeMap(op['condiciones_equipo']);
    final condiciones = condicionesRaw.isNotEmpty
        ? CondicionEquipoRequest(condicionesRaw)
        : null;
    final controlLlantasRaw = _decodeMap(op['control_llantas']);
    final controlLlantas = controlLlantasRaw.isNotEmpty
        ? ControlLlantasRequest(controlLlantasRaw)
        : null;
    final checkList = _decodeList(
      op['check_list'],
    ).map((e) => ChecklistRespuestaRequest.fromJson(e)).toList();
    final checkListOrNull = checkList.isNotEmpty ? checkList : null;

    final registrosRaw = _cleanRegistros(op['registros']);

    switch (tipo) {
      case 'tal_largo':
        return OperacionTalLargoUpsertRequest(
          fecha: op['fecha'],
          turnoId: op['turno_id'],
          laborId: op['labor_id'],
          operadorId: op['operador_id'],
          jefeGuardiaId: op['jefe_guardia_id'],
          equipoId: op['equipo_id'],
          estado: estadoOperacion,
          envio: enviado,
          revisado: op['revisado'],
          aprobacion: op['aprobacion'],
          horometros: horometros,
          condicionesEquipo: condiciones,
          controlLlantas: controlLlantas,
          checkList: checkListOrNull,
          registros: _buildRegistros(
            registrosRaw,
            RegistroOperacionTalLargoDetalleRequest.fromJson,
          ),
        );

      case 'tal_horizontal':
        return OperacionTalHorizontalUpsertRequest(
          fecha: op['fecha'],
          turnoId: op['turno_id'],
          laborId: op['labor_id'],
          operadorId: op['operador_id'],
          jefeGuardiaId: op['jefe_guardia_id'],
          equipoId: op['equipo_id'],
          estado: estadoOperacion,
          envio: enviado,
          revisado: op['revisado'],
          aprobacion: op['aprobacion'],
          horometros: horometros,
          condicionesEquipo: condiciones,
          controlLlantas: controlLlantas,
          checkList: checkListOrNull,
          registros: _buildRegistros(
            registrosRaw,
            RegistroOperacionTalHorizontalDetalleRequest.fromJson,
          ),
        );

      case 'carguio':
        return OperacionCarguioUpsertRequest(
          fecha: op['fecha'],
          turnoId: op['turno_id'],
          laborId: op['labor_id'],
          operadorId: op['operador_id'],
          jefeGuardiaId: op['jefe_guardia_id'],
          equipoId: op['equipo_id'],
          estado: estadoOperacion,
          envio: enviado,
          revisado: op['revisado'],
          aprobacion: op['aprobacion'],
          horometros: horometros,
          condicionesEquipo: condiciones,
          controlLlantas: controlLlantas,
          checkList: checkListOrNull,
          registros: _buildRegistros(
            registrosRaw,
            OperacionCarguioRegistroDetalleRequest.fromJson,
          ),
        );

      case 'empernador':
        return OperacionEmpernadorUpsertRequest(
          fecha: op['fecha'],
          turnoId: op['turno_id'],
          laborId: op['labor_id'],
          operadorId: op['operador_id'],
          jefeGuardiaId: op['jefe_guardia_id'],
          equipoId: op['equipo_id'],
          estado: estadoOperacion,
          envio: enviado,
          revisado: op['revisado'],
          aprobacion: op['aprobacion'],
          horometros: horometros,
          condicionesEquipo: condiciones,
          controlLlantas: controlLlantas,
          checkList: checkListOrNull,
          registros: _buildRegistros(
            registrosRaw,
            OperacionEmpernadorRegistroDetalleRequest.fromJson,
          ),
        );

      case 'scalamin':
        return OperacionScalaminUpsertRequest(
          fecha: op['fecha'],
          turnoId: op['turno_id'],
          laborId: op['labor_id'],
          operadorId: op['operador_id'],
          jefeGuardiaId: op['jefe_guardia_id'],
          equipoId: op['equipo_id'],
          estado: estadoOperacion,
          envio: enviado,
          revisado: op['revisado'],
          aprobacion: op['aprobacion'],
          horometros: horometros,
          condicionesEquipo: condiciones,
          controlLlantas: controlLlantas,
          checkList: checkListOrNull,
          registros: _buildRegistros(
            registrosRaw,
            OperacionScalaminRegistroDetalleRequest.fromJson,
          ),
        );

      case 'scissor':
        return OperacionScissorUpsertRequest(
          fecha: op['fecha'],
          turnoId: op['turno_id'],
          laborId: op['labor_id'],
          operadorId: op['operador_id'],
          jefeGuardiaId: op['jefe_guardia_id'],
          equipoId: op['equipo_id'],
          estado: estadoOperacion,
          envio: enviado,
          revisado: op['revisado'],
          aprobacion: op['aprobacion'],
          horometros: horometros,
          condicionesEquipo: condiciones,
          controlLlantas: controlLlantas,
          checkList: checkListOrNull,
          registros: _buildRegistros(
            registrosRaw,
            OperacionScissorRegistroDetalleRequest.fromJson,
          ),
        );

      default:
        return OperacionUpsertRequest(
          fecha: op['fecha'],
          turnoId: op['turno_id'],
          laborId: op['labor_id'],
          operadorId: op['operador_id'],
          jefeGuardiaId: op['jefe_guardia_id'],
          equipoId: op['equipo_id'],
          estado: estadoOperacion,
          envio: enviado,
          revisado: op['revisado'],
          aprobacion: op['aprobacion'],
          horometros: horometros,
          condicionesEquipo: condiciones,
          controlLlantas: controlLlantas,
          checkList: checkListOrNull,
        );
    }
  }

  List<RegistroRequest<T>> _buildRegistros<T>(
    List<Map<String, dynamic>> registros,
    T Function(Map<String, dynamic>) detalleFactory,
  ) {
    if (registros.isEmpty) return [];

    return registros.map((r) {
      final opDetalle = r['operacion'] as Map<String, dynamic>?;
      return RegistroRequest<T>(
        id: r['id'],
        numero: r['numero'] ?? 0,
        estado: r['estado'] ?? '',
        codigo: r['codigo'] ?? '',
        horaInicio: r['hora_inicio'] ?? '',
        horaFinal: r['hora_final'] ?? '',
        operacion: opDetalle != null ? detalleFactory(opDetalle) : null,
      );
    }).toList();
  }

  Map<String, dynamic> _decodeMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is Map) return Map<String, dynamic>.from(value);
    try {
      final decoded = jsonDecode(value as String);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _decodeList(dynamic value) {
    if (value == null) return <Map<String, dynamic>>[];
    if (value is List) {
      return value.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    try {
      final decoded = jsonDecode(value as String);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _cleanRegistros(dynamic value) {
    final registros = _decodeList(value);
    const keysToRemove = {
      'frente_origen',
      'labor_id',
      'mina',
      'zona',
      'area',
      'fase',
      'estructura_mineral',
    };

    return registros.map((registro) {
      final copy = Map<String, dynamic>.from(registro);
      final op = copy['operacion'];
      if (op is Map) {
        final opCopy = Map<String, dynamic>.from(op);
        for (final key in keysToRemove) {
          opCopy.remove(key);
        }
        copy['operacion'] = opCopy;
      }
      return copy;
    }).toList();
  }

  String formatearJson(List<Map<String, dynamic>> jsonData) {
    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }
}
