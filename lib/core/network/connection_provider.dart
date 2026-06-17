import 'package:flutter/material.dart';
import 'package:i_miner/core/sync/sync_service.dart';
import 'connection_service.dart';
import 'connection_status.dart';

// 👇 IMPORTANTE

class ConnectionProvider extends ChangeNotifier {
  final ConnectionService _service = ConnectionService();

  ConnectionStatus _status = ConnectionStatus.offline;

  ConnectionStatus get status => _status;

  ConnectionProvider() {
    _service.initialize();

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
}