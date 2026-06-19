import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/services/envio%20nube/AnfoChanger/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/Carguio/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/Dumper/ExportarDumperService.dart';
import 'package:i_miner/services/envio%20nube/Rompebancos/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/SCISSOR/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/Scalamin/ExportarScalaminService.dart';
import 'package:i_miner/services/envio%20nube/Sostenimiento/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/horizontal/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/largo/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/operaciones_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final OperacionesService _api = OperacionesService();

  Future<void> syncData() async {
    print("🚀 Iniciando sincronización...");

    try {
      await _syncProceso(
        tipo: 'tal_largo',
        getData: _dbHelper.getOperacionesNoEnviadasLargo,
        exportService: ExportarService(_dbHelper),
        marcar: _dbHelper.actualizarEnvio,
      );

      await _syncProceso(
        tipo: 'tal_horizontal',
        getData: _dbHelper.getOperacionesTaladroHorizontalNoEnviadas,
        exportService: ExportarHorizontalService(_dbHelper),
        marcar: _dbHelper.actualizarEnvioHorizontal,
      );

      await _syncProceso(
        tipo: 'empernador',
        getData: _dbHelper.getOperacionesEmpernadorNoEnviadas,
        exportService: ExportarEmpernadorService(_dbHelper),
        marcar: _dbHelper.actualizarEnvioEmpernador,
      );

      await _syncProceso(
        tipo: 'scissor',
        getData: _dbHelper.getOperacionesScissorNoEnviadas,
        exportService: ExportarScissorService(_dbHelper),
        marcar: _dbHelper.actualizarEnvioscissor,
      );

      await _syncProceso(
        tipo: 'anfochanger',
        getData: _dbHelper.getOperacionesAnfoChangerNoEnviadas,
        exportService: ExportarAnfoChangerService(_dbHelper),
        marcar: _dbHelper.actualizarEnvioRAnfoChanger,
      );

      await _syncProceso(
        tipo: 'rompebanco',
        getData: _dbHelper.getOperacionesRompeBancosNoEnviadas,
        exportService: ExportarRompebancoService(_dbHelper),
        marcar: _dbHelper.actualizarEnvioRompeBancos,
      );

      await _syncProceso(
        tipo: 'carguio',
        getData: _dbHelper.getOperacionesCarguioNoEnviadas,
        exportService: ExportarCarguioService(_dbHelper),
        marcar: _dbHelper.actualizarEnvioCarguio,
      );

      await _syncProceso(
        tipo: 'dumper',
        getData: _dbHelper.getOperacionesDumperNoEnviadas,
        exportService: ExportarDumperService(_dbHelper),
        marcar: _dbHelper.actualizarEnvioDumper,
      );

      await _syncProceso(
        tipo: 'scalamin',
        getData: _dbHelper.getOperacionesScalaminNoEnviadas,
        exportService: ExportarScalaminService(_dbHelper),
        marcar: _dbHelper.actualizarEnvioScalamin,
      );

      print("✅ Sincronización completa");
    } catch (e) {
      print("❌ Error en sync: $e");
    }
  }

  /// 🔥 MÉTODO GENÉRICO (EL CORAZÓN)
  Future<void> _syncProceso({
    required String tipo,
    required Future<List<Map<String, dynamic>>> Function() getData,
    required dynamic exportService,
    required Future<void> Function(int) marcar,
  }) async {
    print("📦 Sincronizando: $tipo");

    final data = await getData();

    /// Solo los no enviados
    final pendientes = data.where((e) => e['envio'] == 0).toList();

    if (pendientes.isEmpty) {
      print("✔️ $tipo sin pendientes");
      return;
    }

    final ids = pendientes.map<int>((e) => e['id'] as int).toSet();

    final jsonData = await exportService.prepararDatosParaExportar(
      ids,
      pendientes,
    );

    if (jsonData.isEmpty) {
      print("✔️ $tipo sin registros exportables");
      return;
    }

    /// quitar local_id
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
