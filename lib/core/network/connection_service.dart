import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'connection_status.dart';

class ConnectionService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker =
      InternetConnectionChecker();

  final StreamController<ConnectionStatus> _controller =
      StreamController<ConnectionStatus>.broadcast();

  Stream<ConnectionStatus> get connectionStream => _controller.stream;

  void initialize() {
    // Escuchar cambios de red (wifi, datos, etc.)
    _connectivity.onConnectivityChanged.listen((_) async {
      await _checkInternet();
    });

    // También escuchar cambios reales de internet
    _internetChecker.onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        _controller.add(ConnectionStatus.online);
      } else {
        _controller.add(ConnectionStatus.offline);
      }
    });
  }

  Future<void> _checkInternet() async {
    bool hasInternet = await _internetChecker.hasConnection;

    if (hasInternet) {
      _controller.add(ConnectionStatus.online);
    } else {
      _controller.add(ConnectionStatus.offline);
    }
  }

  void dispose() {
    _controller.close();
  }
}