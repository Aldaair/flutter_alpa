import 'package:flutter/material.dart';
import 'package:i_miner/core/sync/sync_service.dart';
import 'connection_service.dart';
import 'connection_status.dart';

// 👇 IMPORTANTE

class ConnectionProvider extends ChangeNotifier {
  final ConnectionService _service = ConnectionService();

  ConnectionStatus _status;

  ConnectionStatus get status => _status;

  ConnectionProvider() : _status = ConnectionStatus.offline {
    _service.initialize();
    _status = _service.lastStatus;

    _service.connectionStream.listen((newStatus) async {
      final previousStatus = _status;

      _status = newStatus;
      notifyListeners();

      // 🔥 AQUÍ DETECTAMOS EL CAMBIO CLAVE
      if (previousStatus == ConnectionStatus.offline &&
          newStatus == ConnectionStatus.online) {

        print("🟢 Internet recuperado → lanzar sync");

        await SyncService().syncData(); // 👈 LLAMADA IMPORTANTE
      }
    });
  }

  bool get isOnline => _status == ConnectionStatus.online;

  /// Verifica conexión en tiempo real. Útil en momentos críticos (login, sync manual).
  Future<bool> checkNow() async {
    final online = await _service.checkNow();
    return online;
  }
}