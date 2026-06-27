import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/services/envio%20nube/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/operaciones_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final OperacionesService _api = OperacionesService();
  late final ExportarService _export = ExportarService(_dbHelper);

  Future<void> syncData() async {
    print("🚀 Iniciando sincronización...");

    try {
      await _syncProceso(
        tipo: 'tal_largo',
        getData: _dbHelper.getOperacionesNoEnviadasLargo,
        marcar: _dbHelper.actualizarEnvio,
      );

      await _syncProceso(
        tipo: 'tal_horizontal',
        getData: _dbHelper.getOperacionesTaladroHorizontalNoEnviadas,
        marcar: _dbHelper.actualizarEnvioHorizontal,
      );

      await _syncProceso(
        tipo: 'empernador',
        getData: _dbHelper.getOperacionesEmpernadorNoEnviadas,
        marcar: _dbHelper.actualizarEnvioEmpernador,
      );

      await _syncProceso(
        tipo: 'scissor',
        getData: _dbHelper.getOperacionesScissorNoEnviadas,
        marcar: _dbHelper.actualizarEnvioscissor,
      );

      await _syncProceso(
        tipo: 'anfochanger',
        getData: _dbHelper.getOperacionesAnfoChangerNoEnviadas,
        marcar: _dbHelper.actualizarEnvioRAnfoChanger,
      );

      await _syncProceso(
        tipo: 'rompebanco',
        getData: _dbHelper.getOperacionesRompeBancosNoEnviadas,
        marcar: _dbHelper.actualizarEnvioRompeBancos,
      );

      await _syncProceso(
        tipo: 'carguio',
        getData: _dbHelper.getOperacionesCarguioNoEnviadas,
        marcar: _dbHelper.actualizarEnvioCarguio,
      );

      await _syncProceso(
        tipo: 'dumper',
        getData: _dbHelper.getOperacionesDumperNoEnviadas,
        marcar: _dbHelper.actualizarEnvioDumper,
      );

      await _syncProceso(
        tipo: 'scalamin',
        getData: _dbHelper.getOperacionesScalaminNoEnviadas,
        marcar: _dbHelper.actualizarEnvioScalamin,
      );

      print("✅ Sincronización completa");
    } catch (e) {
      print("❌ Error en sync: $e");
    }
  }

  Future<void> _syncProceso({
    required String tipo,
    required Future<List<Map<String, dynamic>>> Function() getData,
    required Future<void> Function(int) marcar,
  }) async {
    print("📦 Sincronizando: $tipo");

    final data = await getData();
    final pendientes = data.where((e) {
      final enviado = e['enviado'] ?? e['envio'] ?? 0;
      return enviado == 0;
    }).toList();

    if (pendientes.isEmpty) {
      print("✔️ $tipo sin pendientes");
      return;
    }

    final ids = pendientes.map<int>((e) => e['id'] as int).toSet();
    final jsonData = await _export.prepararDatosParaExportar(
      tipo,
      ids,
      pendientes,
    );

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
        await marcar(item['local_id']);
      }
      print("✅ $tipo sincronizado (${jsonData.length})");
    } else {
      print("❌ Error enviando $tipo");
    }
  }
}
