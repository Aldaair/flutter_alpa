import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/services/envio%20nube/exportar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExportarService service;

  setUp(() {
    service = ExportarService(DatabaseHelper());
  });

  test('exports carguio registros with only contract fields', () async {
    final jsonData = await service.prepararDatosParaExportar(
      'carguio',
      {31},
      [
        {
          'id': 31,
          'fecha': '2026-07-16',
          'turno_id': 1,
          'operador_id': 10,
          'jefe_guardia_id': 20,
          'equipo_id': 30,
          'estado': 'cerrado',
          'envio': 0,
          'registros':
              '[{"id":1,"numero":1,"estado":"ok","codigo":"C-1","hora_inicio":"08:00","hora_final":"09:00","operacion":{"labor_id":2,"destino_id":9,"ubicacion_destino_id":9,"ubicacion_destino":"Tolva 1","n_cucharas":5,"observaciones":"ready"}}]',
          'horometros': '{}',
          'check_list': '[]',
          'condiciones_equipo': '{}',
          'control_llantas': '{}',
        },
      ],
    );

    final operacion =
        (jsonData.single['registros'] as List).single['operacion']
            as Map<String, dynamic>;

    expect(operacion, {
      'labor_id': 2,
      'destino_id': 9,
      'n_cucharas': 5,
      'observaciones': 'ready',
    });
  });

  test(
    'keeps null labor path and maps legacy destination id to destino_id',
    () async {
      final jsonData = await service.prepararDatosParaExportar(
        'carguio',
        {32},
        [
          {
            'id': 32,
            'fecha': '2026-07-16',
            'turno_id': 2,
            'operador_id': 11,
            'jefe_guardia_id': 21,
            'equipo_id': 31,
            'estado': 'cerrado',
            'envio': 0,
            'registros':
                '[{"id":1,"numero":1,"estado":"ok","codigo":"C-2","hora_inicio":"10:00","hora_final":"11:00","operacion":{"labor_id":null,"ubicacion_destino_id":7,"ubicacion_destino":"Cancha 2","n_cucharas":3,"observaciones":"legacy destination"}}]',
            'horometros': '{}',
            'check_list': '[]',
            'condiciones_equipo': '{}',
            'control_llantas': '{}',
          },
        ],
      );

      final operacion =
          (jsonData.single['registros'] as List).single['operacion']
              as Map<String, dynamic>;

      expect(operacion, {
        'destino_id': 7,
        'n_cucharas': 3,
        'observaciones': 'legacy destination',
      });
      expect(operacion.containsKey('labor_id'), isFalse);
    },
  );
}
