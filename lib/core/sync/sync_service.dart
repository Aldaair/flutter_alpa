import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/sync_repository.dart';
import 'package:i_miner/core/sync/export_payload_utils.dart';
import 'package:i_miner/services/envio%20nube/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/operaciones_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static bool _isSyncInProgress = false;

  factory SyncService({
    SyncRepository? syncRepository,
    OperacionesService? api,
    ExportarService? exportService,
    Map<String, String>? processTables,
  }) {
    if (syncRepository != null ||
        api != null ||
        exportService != null ||
        processTables != null) {
      return SyncService._internal(
        syncRepository: syncRepository,
        api: api,
        exportService: exportService,
        processTables: processTables,
      );
    }
    return _instance;
  }

  SyncService._internal({
    SyncRepository? syncRepository,
    OperacionesService? api,
    ExportarService? exportService,
    Map<String, String>? processTables,
  }) : _syncRepo = syncRepository ?? SyncRepository(),
       _api = api ?? OperacionesService(),
       _export = exportService ?? ExportarService(DatabaseHelper()),
       _processTables = processTables ?? _defaultProcessTables;

  final SyncRepository _syncRepo;
  final OperacionesService _api;
  final ExportarService _export;

  /// Maps endpoint type table name.
  static const Map<String, String> _defaultProcessTables = {
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

  final Map<String, String> _processTables;

  bool get isSyncInProgress => _isSyncInProgress;

  Future<T?> runGuardedOperation<T>(
    Future<T> Function() operation, {
    String source = 'sync',
  }) async {
    if (_isSyncInProgress) {
      print('⚠️ Skipping $source because another sync/send is already running');
      return null;
    }

    _isSyncInProgress = true;
    print('🔒 Sync lock acquired by $source');

    try {
      return await operation();
    } finally {
      _isSyncInProgress = false;
      print('🔓 Sync lock released by $source');
    }
  }

  Future<void> syncData() async {
    await runGuardedOperation(() async {
      print("🚀 Iniciando sincronización...");

      try {
        for (final entry in _processTables.entries) {
          await _syncProceso(tipo: entry.key, tableName: entry.value);
        }

        print("✅ Sincronización completa");
      } catch (e) {
        print("❌ Error en sync: $e");
      }
    }, source: 'auto-sync');
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

    final dataParaEnviar = jsonData.map(preparePayloadForSend).toList();

    final result = await _api.crear(
      tipo,
      dataParaEnviar,
      onItemProcessed: (itemResult) async {
        if (!itemResult.success) {
          return;
        }

        final localId = _readLocalId(jsonData, itemResult.localIndex);
        if (localId == null) {
          throw StateError(
            '[$tipo] Missing local_id for index ${itemResult.localIndex}',
          );
        }

        await _syncRepo.markAsSent(tableName, localId);
        print(
          '✅ [$tipo][${itemResult.localIndex + 1}] Marked local_id=$localId as sent',
        );
      },
    );

    if (result.successCount > 0) {
      print("✅ $tipo sincronizado (${result.successCount}/${jsonData.length})");
    }

    if (!result.isSuccess) {
      print("❌ Error enviando $tipo");
      print(
        '❌ [$tipo] attempted=${result.attemptedCount} success=${result.successCount} '
        'failed=${result.failureCount} skipped=${result.skippedCount}',
      );
    }
  }

  int? _readLocalId(List<Map<String, dynamic>> jsonData, int index) {
    if (index < 0 || index >= jsonData.length) {
      return null;
    }

    final value = jsonData[index]['local_id'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }
}
