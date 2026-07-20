import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:i_miner/services/envio%20nube/operaciones_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'returns per-item results and stops after the first failed POST',
    () async {
      var callCount = 0;
      final service = OperacionesService(
        client: MockClient((request) async {
          callCount++;

          if (callCount == 1) {
            return http.Response('{"ok":true}', 201);
          }

          return http.Response('{"ok":false}', 500);
        }),
      );

      final processedIndexes = <int>[];
      final result = await service.crear(
        'carguio',
        const [
          {'id': 1},
          {'id': 2},
          {'id': 3},
        ],
        onItemProcessed: (itemResult) async {
          processedIndexes.add(itemResult.localIndex);
        },
      );

      expect(callCount, 2);
      expect(processedIndexes, [0, 1]);
      expect(result.isSuccess, isFalse);
      expect(result.successCount, 1);
      expect(result.failureCount, 1);
      expect(result.skippedCount, 1);
      expect(result.items.map((item) => item.localIndex), [0, 1]);
      expect(result.items.first.success, isTrue);
      expect(result.items.last.success, isFalse);
      expect(result.items.last.statusCode, 500);
    },
  );
}
