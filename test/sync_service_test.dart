import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/sync_repository.dart';
import 'package:i_miner/core/sync/sync_service.dart';
import 'package:i_miner/services/envio%20nube/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/operaciones_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('marks each successful record as sent before a later failure', () async {
    final repository = _FakeSyncRepository(
      rowsByTable: {
        'Operacion_carguio': [
          {'id': 101, 'enviado': 0, 'cerrado': 1},
          {'id': 102, 'enviado': 0, 'cerrado': 1},
          {'id': 103, 'enviado': 0, 'cerrado': 1},
        ],
      },
    );
    final exportService = _FakeExportarService([
      {'local_id': 101, 'client_request_id': '101', 'payload': 'first'},
      {'local_id': 102, 'client_request_id': '102', 'payload': 'second'},
      {'local_id': 103, 'client_request_id': '103', 'payload': 'third'},
    ]);

    var callCount = 0;
    final requestBodies = <Map<String, dynamic>>[];
    final api = OperacionesService(
      client: MockClient((request) async {
        callCount++;
        requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);

        if (callCount == 1) {
          return http.Response('{"ok":true}', 201);
        }

        return http.Response('{"ok":false}', 500);
      }),
    );

    final service = SyncService(
      syncRepository: repository,
      exportService: exportService,
      api: api,
      processTables: const {'carguio': 'Operacion_carguio'},
    );

    await service.syncData();

    expect(repository.markedIds, [101]);
    expect(callCount, 2);
    expect(
      requestBodies,
      [
        {'client_request_id': '101', 'payload': 'first'},
        {'client_request_id': '102', 'payload': 'second'},
      ],
    );
  });

  test('prevents overlapping sync executions with the shared guard', () async {
    final service = SyncService(
      syncRepository: _FakeSyncRepository(rowsByTable: const {}),
      exportService: _FakeExportarService(const []),
      api: OperacionesService(
        client: MockClient((request) async => http.Response('{}', 200)),
      ),
      processTables: const {},
    );

    final completer = Completer<String>();

    final firstRun = service.runGuardedOperation(
      () => completer.future,
      source: 'test-first-run',
    );
    final secondRun = await service.runGuardedOperation(
      () async => 'second',
      source: 'test-second-run',
    );

    expect(secondRun, isNull);

    completer.complete('first');

    expect(await firstRun, 'first');
  });
}

class _FakeSyncRepository extends SyncRepository {
  _FakeSyncRepository({required this.rowsByTable});

  final Map<String, List<Map<String, dynamic>>> rowsByTable;
  final List<int> markedIds = [];

  @override
  Future<List<Map<String, dynamic>>> getUnsentOperations(
    String tableName,
  ) async {
    return rowsByTable[tableName] ?? const [];
  }

  @override
  Future<void> markAsSent(String tableName, int id) async {
    markedIds.add(id);
  }
}

class _FakeExportarService extends ExportarService {
  _FakeExportarService(this.response) : super(DatabaseHelper());

  final List<Map<String, dynamic>> response;

  @override
  Future<List<Map<String, dynamic>>> prepararDatosParaExportar(
    String tipo,
    Set<int> selectedItems,
    List<Map<String, dynamic>> operacionData,
  ) async {
    return response;
  }
}
