import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/models/api/v2/operation_dtos.dart';

void main() {
  test('typed upsert request serializes client_request_id', () {
    final request = OperacionCarguioUpsertRequest(
      fecha: '2026-07-20',
      clientRequestId: 'req-123',
      turnoId: 2,
      registros: const [],
    );

    expect(request.toJson()['client_request_id'], 'req-123');
  });
}
