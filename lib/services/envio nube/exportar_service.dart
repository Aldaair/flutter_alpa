import 'dart:convert';
import 'package:i_miner/config/data/database_helper.dart';

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

      if (tipo == 'tal_horizontal' && !_isSyncableV2(op)) continue;

      final map = _buildOperationMap(op, tipo);
      map['local_id'] = id;
      results.add(map);
    }

    return results;
  }

  Map<String, dynamic> _buildOperationMap(
    Map<String, dynamic> op,
    String tipo,
  ) {
    final horometros = _decodeMap(op['horometros']);
    final condiciones = _decodeMap(op['condiciones_equipo']);
    final controlLlantas = _decodeMap(op['control_llantas']);
    final registros = _cleanRegistros(op['registros']);
    final checklist = _decodeList(op['check_list']);

    final map = <String, dynamic>{
      // v2 contract fields
      'fecha': op['fecha'],
      'turno_id': op['turno_id'],
      'labor_id': op['labor_id'],
      'operador_id': op['operador_id'],
      'jefe_guardia_id': op['jefe_guardia_id'],
      'equipo_id': op['equipo_id'],
      'estado': op['estado'] ?? 'activo',
      'envio': op['envio'] ?? 0,
      'revisado': op['revisado'],
      'aprobacion': op['aprobacion'],
      'horometros': horometros,
      'condiciones_equipo': condiciones,
      'check_list': checklist,
      'control_llantas': controlLlantas,
      'registros': registros,

      // display / legacy fields (ignored by v2 API via JsonPropertyName)
      'turno': op['turno'] ?? '',
      'seccion': op['seccion'] ?? '',
      'operador': op['operador'] ?? '',
      'jefe_guardia': op['jefe_guardia'] ?? '',
      'equipo': op['equipo'] ?? '',
      'n_equipo': op['n_equipo'] ?? '',
      'modelo_equipo': op['modelo_equipo'] ?? '',
      'frente_origen': op['frente_origen'],
      'registrador_usuario_id': op['registrador_usuario_id'],
      'registrador_nombre': op['registrador_nombre'],
      'seccion_id': op['seccion_id'],
      'capacidad': op['capacidad'] ?? '',
    };

    // tipo-specific nested fields
    if (tipo == 'carguio' || tipo == 'dumper') {
      map['tipo_equipo'] = _decodeMap(op['tipo_equipo']);
      map['programa_trabajo'] = _decodeMap(op['programa_trabajo']);
    }

    if (tipo == 'carguio' || tipo == 'dumper' || tipo == 'empernador') {
      map['check_list_telemando'] = _decodeList(op['check_list_telemando']);
    }

    return map;
  }

  bool _isSyncableV2(Map<String, dynamic> op) {
    if (op.isEmpty) return false;
    return op['identity_version'] == 2 &&
        op['syncable'] == 1 &&
        op['operador_id'] != null &&
        op['equipo_id'] != null &&
        op['jefe_guardia_id'] != null;
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
      'tipo_labor',
      'labor',
      'ala',
      'nivel',
    };

    return registros.map((registro) {
      final copy = Map<String, dynamic>.from(registro);
      final operacion = copy['operacion'];
      if (operacion is Map) {
        final opCopy = Map<String, dynamic>.from(operacion);
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
