import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/sync_repository.dart';
import 'package:i_miner/services/envio%20nube/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/operaciones_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SyncRepository _syncRepo = SyncRepository();
  final OperacionesService _api = OperacionesService();
  late final ExportarService _export = ExportarService(DatabaseHelper());

  /// Maps endpoint type table name.
  static const _processTables = {
    'tal_largo': 'Operacion_tal_largo',
    'tal_horizontal': 'Operacion_tal_horizontal',
    'empernador': 'Operacion_empernador',
    'scissor': 'Operacion_scissor',
    'anfochanger': 'Operacion_anfochanger',
    'rompebanco': 'Operacion_rompebanco',
    'carguio': 'Operacion_carguio',
    'acarreo': 'Operacion_acarreo',
    'dumper': 'Operacion_Dumper',
    'scalamin': 'Operacion_Scalamin',
  };

  Future<void> syncData() async {
    print("🚀 Iniciando sincronización...");

    try {
      for (final entry in _processTables.entries) {
        await _syncProceso(tipo: entry.key, tableName: entry.value);
      }

      print("✅ Sincronización completa");
    } catch (e) {
      print("❌ Error en sync: $e");
    }
  }

  Future<void> _syncProceso({
    required String tipo,
    required String tableName,
  }) async {
    print("📦 Sincronizando: $tipo");

    final data = await _syncRepo.getUnsentOperations(tableName);

    if (data.isEmpty) {
      print("✔️ $tipo sin pendientes");
      return;
    }

    final ids = data.map<int>((e) => e['id'] as int).toSet();
    final jsonData = await _export.prepararDatosParaExportar(tipo, ids, data);

    if (jsonData.isEmpty) {
      print("✔️ $tipo sin registros exportables");
      return;
    }

    final dataParaEnviar = jsonData.map((item) {
      final copia = Map<String, dynamic>.from(item);
      copia.remove('local_id');
      return copia;
    }).toList();

    final success = await _api.crear(tipo, dataParaEnviar);

    if (success) {
      for (var item in jsonData) {
        await _syncRepo.markAsSent(tableName, item['local_id']);
      }
      print("✅ $tipo sincronizado (${jsonData.length})");
    } else {
      print("❌ Error enviando $tipo");
    }
  }
}
