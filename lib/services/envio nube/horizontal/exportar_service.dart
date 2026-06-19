import 'dart:convert';
import 'package:i_miner/config/data/database_helper.dart';

class ExportarHorizontalService {
  final DatabaseHelper dbHelper;

  ExportarHorizontalService(this.dbHelper);

  Future<List<Map<String, dynamic>>> prepararDatosParaExportar(
    Set<int> selectedItems,
    List<Map<String, dynamic>> operacionData,
  ) async {
    final List<Map<String, dynamic>> jsonDataList = [];

    List<Map<String, dynamic>> parseList(String? value) {
      try {
        final decoded = jsonDecode(value ?? '[]');
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      } catch (_) {}
      return [];
    }

    Map<String, dynamic> parseMap(String? value) {
      try {
        final decoded = jsonDecode(value ?? '{}');
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
      return {};
    }

    for (var id in selectedItems) {
      final operacion = operacionData.firstWhere(
        (op) => op['id'] == id,
        orElse: () => {},
      );

      if (!_isSyncableApiV2Row(operacion)) {
        continue;
      }

      final estados = parseList(operacion['registros']);
      final horometros = parseMap(operacion['horometros']);
      final checklist = parseList(operacion['check_list']);
      final condiciones = parseMap(operacion['condiciones_equipo']);
      final controlLlantas = parseMap(operacion['control_llantas']);

      jsonDataList.add({
        "local_id": id,
        "fecha": operacion['fecha'] ?? "",
        "turno": operacion['turno'] ?? "",
        "seccion": operacion['seccion'] ?? "",
        "seccion_id": operacion['seccion_id'],
        "operador": operacion['operador'] ?? "",
        "operador_id": operacion['operador_id'],
        "jefe_guardia": operacion['jefe_guardia'] ?? "",
        "jefe_guardia_id": operacion['jefe_guardia_id'],
        "equipo": operacion['equipo'] ?? "",
        "equipo_id": operacion['equipo_id'],
        "n_equipo": operacion['n_equipo'] ?? "",
        "modelo_equipo": operacion['modelo_equipo'] ?? "",
        "estado": operacion['estado'] ?? "activo",
        "envio": operacion['envio'] ?? 0,
        "registros": jsonEncode(estados),
        "horometros": jsonEncode(horometros),
        "condiciones_equipo": jsonEncode(condiciones),
        "check_list": jsonEncode(checklist),
        "control_llantas": jsonEncode(controlLlantas),
      });
    }

    return jsonDataList;
  }

  bool _isSyncableApiV2Row(Map<String, dynamic> operacion) {
    if (operacion.isEmpty) {
      return false;
    }

    return operacion['identity_version'] == 2 &&
        operacion['syncable'] == 1 &&
        operacion['operador_id'] != null &&
        operacion['equipo_id'] != null &&
        operacion['seccion_id'] != null &&
        operacion['jefe_guardia_id'] != null;
  }

  String formatearJson(List<Map<String, dynamic>> jsonData) {
    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }
}
