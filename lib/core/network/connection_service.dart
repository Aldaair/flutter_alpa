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

  ConnectionStatus _lastStatus = ConnectionStatus.offline;

  ConnectionStatus get lastStatus => _lastStatus;

  Stream<ConnectionStatus> get connectionStream => _controller.stream;

  void initialize() {
    _connectivity.onConnectivityChanged.listen((_) async {
      await _checkInternet();
    });

    _internetChecker.onStatusChange.listen((status) {
      _lastStatus = status == InternetConnectionStatus.connected
          ? ConnectionStatus.online
          : ConnectionStatus.offline;
      _controller.add(_lastStatus);
    });

    _checkInternet();
  }

  Future<void> _checkInternet() async {
    bool hasInternet = await _internetChecker.hasConnection;
    _lastStatus =
        hasInternet ? ConnectionStatus.online : ConnectionStatus.offline;
    _controller.add(_lastStatus);
  }

  /// Verifica conexión en tiempo real y actualiza el estado.
  Future<bool> checkNow() async {
    bool hasInternet = await _internetChecker.hasConnection;
    _lastStatus =
        hasInternet ? ConnectionStatus.online : ConnectionStatus.offline;
    _controller.add(_lastStatus);
    return hasInternet;
  }

  void dispose() {
    _controller.close();
  }
}
