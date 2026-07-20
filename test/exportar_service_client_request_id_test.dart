import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/services/envio%20nube/exportar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExportarService service;

  setUp(() {
    service = ExportarService(DatabaseHelper());
  });

  test('adds client_request_id from local_id for v2 operation payloads', () async {
    final jsonData = await service.prepararDatosParaExportar(
      'carguio',
      {77},
      [
        {
          'id': 77,
          'fecha': '2026-07-20',
          'turno_id': 2,
          'labor_id': 9,
          'operador_id': 10,
          'jefe_guardia_id': 11,
          'equipo_id': 12,
          'estado': 'cerrado',
          'envio': 0,
          'registros': '[]',
          'horometros': '{}',
          'check_list': '[]',
          'condiciones_equipo': '{}',
          'control_llantas': '{}',
        },
      ],
    );

    expect(jsonData, hasLength(1));
    expect(jsonData.single['local_id'], 77);
    expect(jsonData.single['client_request_id'], '77');
  });
}
