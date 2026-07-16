import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/services/envio%20nube/exportar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExportarService service;

  setUp(() {
    service = ExportarService(DatabaseHelper());
  });

  test('exports locomotora acarreo registros without n_cucharas', () async {
    final jsonData = await service.prepararDatosParaExportar(
      'acarreo',
      {21},
      [
        {
          'id': 21,
          'fecha': '2026-07-15',
          'turno_id': 1,
          'operador_id': 10,
          'jefe_guardia_id': 20,
          'equipo_id': 30,
          'tipo_equipo': 'LOCOMOTORA',
          'estado': 'cerrado',
          'envio': 0,
          'registros':
              '[{"id":1,"numero":1,"estado":"ok","codigo":"A-1","hora_inicio":"08:00","hora_final":"09:00","operacion":{"labor_id":2,"ubicacion_destino_id":3,"ubicacion_destino":"Tolva 1","n_cucharas":0,"n_carros":4,"observaciones":"ready"}}]',
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

    expect(operacion.containsKey('n_cucharas'), isFalse);
    expect(operacion['n_carros'], 4);
  });

  test('exports volquete acarreo registros without n_carros', () async {
    final jsonData = await service.prepararDatosParaExportar(
      'acarreo',
      {22},
      [
        {
          'id': 22,
          'fecha': '2026-07-15',
          'turno_id': 1,
          'operador_id': 11,
          'jefe_guardia_id': 21,
          'equipo_id': 31,
          'tipo_equipo': 'VOLQUETE',
          'estado': 'cerrado',
          'envio': 0,
          'registros':
              '[{"id":1,"numero":1,"estado":"ok","codigo":"A-2","hora_inicio":"10:00","hora_final":"11:00","operacion":{"labor_id":2,"ubicacion_destino_id":3,"ubicacion_destino":"Cancha 2","n_cucharas":6,"n_carros":0,"observaciones":"ready"}}]',
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

    expect(operacion['n_cucharas'], 6);
    expect(operacion.containsKey('n_carros'), isFalse);
  });

  test('preserves both acarreo metrics when tipo_equipo is unknown', () async {
    final jsonData = await service.prepararDatosParaExportar(
      'acarreo',
      {23},
      [
        {
          'id': 23,
          'fecha': '2026-07-15',
          'turno_id': 1,
          'operador_id': 12,
          'jefe_guardia_id': 22,
          'equipo_id': 32,
          'estado': 'cerrado',
          'envio': 0,
          'registros':
              '[{"id":1,"numero":1,"estado":"ok","codigo":"A-3","hora_inicio":"12:00","hora_final":"13:00","operacion":{"labor_id":2,"ubicacion_destino_id":3,"ubicacion_destino":"Stockpile","n_cucharas":2,"n_carros":1,"observaciones":"legacy"}}]',
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

    expect(operacion['n_cucharas'], 2);
    expect(operacion['n_carros'], 1);
  });
}
