import 'package:i_miner/config/data/database_helper.dart';

class ChecklistHelper {
  static Future<List<Map<String, dynamic>>> enrichForDisplay({
    required String proceso,
    required List<Map<String, dynamic>> savedDecisions,
  }) async {
    final catalog =
        await DatabaseHelper().getCheckListByProceso(proceso);

    return catalog.map((item) {
      final saved = savedDecisions.firstWhere(
        (s) => s['id'] == item['id'],
        orElse: () => <String, dynamic>{},
      );
      return {
        'id': item['id'],
        'categoria_id': item['categoria_id'],
        'nombre': item['nombre'],
        'categoria': item['categoria'],
        'orden': item['orden'],
        'categoria_orden': item['categoria_orden'],
        'decision': saved['decision'] ?? 1,
        'observacion': saved['observacion'] ?? '',
      };
    }).toList();
  }

  static List<Map<String, dynamic>> stripForSave(
    List<Map<String, dynamic>> enriched,
  ) {
    return enriched.map((e) {
      return {
        'id': e['id'],
        'decision': e['decision'],
        'observacion': e['observacion'],
      };
    }).toList();
  }
}
