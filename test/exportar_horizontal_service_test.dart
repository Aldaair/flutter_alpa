import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/services/envio%20nube/exportar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExportarService service;

  setUp(() {
    service = ExportarService(DatabaseHelper());
  });

  test(
    'exports persisted remote IDs for syncable api v2 horizontal rows',
    () async {
      final jsonData = await service.prepararDatosParaExportar(
        'tal_horizontal',
        {10},
        [
          {
            'id': 10,
            'fecha': '2026-06-17',
            'turno': 'DAY',
            'seccion': 'Section label snapshot',
            'seccion_id': 30,
            'operador': 'Operator label snapshot',
            'operador_id': 44,
            'jefe_guardia': 'Guard label snapshot',
            'jefe_guardia_id': 40,
            'equipo': 'Equipment label snapshot',
            'equipo_id': 20,
            'n_equipo': 'TH-01',
            'modelo_equipo': 'S1D',
            'estado': 'cerrado',
            'envio': 0,
            'identity_version': 2,
            'syncable': 1,
            'registros': '[{"estado":"ok"}]',
            'horometros': '{"diesel":{"inicio":1,"final":2}}',
            'check_list': '[{"item":"brakes","checked":true}]',
            'condiciones_equipo': '{"op":true}',
            'control_llantas': '{"numero1":true}',
          },
        ],
      );

      expect(jsonData, hasLength(1));

      final payload = jsonData.single;
      expect(payload['local_id'], 10);
      expect(payload['operador_id'], 44);
      expect(payload['equipo_id'], 20);
      expect(payload['seccion_id'], 30);
      expect(payload['jefe_guardia_id'], 40);
      expect(payload['operador'], 'Operator label snapshot');
      expect(payload['equipo'], 'Equipment label snapshot');
      expect(payload['registros'], [
        {'estado': 'ok'},
      ]);
    },
  );

  test(
    'exports ids without depending on legacy label-based identity',
    () async {
      final jsonData = await service.prepararDatosParaExportar(
        'tal_horizontal',
        {11},
        [
          {
            'id': 11,
            'fecha': '2026-06-17',
            'turno': 'NIGHT',
            'seccion': 'label no longer matches cache',
            'seccion_id': 31,
            'operador': 'operator label changed',
            'operador_id': 45,
            'jefe_guardia': 'guard label changed',
            'jefe_guardia_id': 41,
            'equipo': 'equipment label changed',
            'equipo_id': 21,
            'n_equipo': 'TH-99',
            'modelo_equipo': 'OLD-MODEL',
            'estado': 'cerrado',
            'envio': 0,
            'identity_version': 2,
            'syncable': 1,
            'registros': '[]',
            'horometros': '{}',
            'check_list': '[]',
            'condiciones_equipo': '{}',
            'control_llantas': '{}',
          },
        ],
      );

      expect(jsonData, hasLength(1));
      expect(jsonData.single['operador_id'], 45);
      expect(jsonData.single['equipo_id'], 21);
      expect(jsonData.single['seccion_id'], 31);
      expect(jsonData.single['jefe_guardia_id'], 41);
    },
  );

  test(
    'skips drafts and legacy rows when exporting horizontal api v2 payloads',
    () async {
      final jsonData = await service.prepararDatosParaExportar(
        'tal_horizontal',
        {12, 13, 14},
        [
          {
            'id': 12,
            'fecha': '2026-06-17',
            'turno': 'DAY',
            'seccion': 'Section A',
            'seccion_id': 32,
            'operador': 'Operator A',
            'operador_id': 46,
            'jefe_guardia': 'Guard A',
            'jefe_guardia_id': 42,
            'equipo': 'Equipment A',
            'equipo_id': 22,
            'n_equipo': 'TH-02',
            'modelo_equipo': 'S2D',
            'estado': 'cerrado',
            'envio': 0,
            'identity_version': 2,
            'syncable': 1,
            'registros': '[]',
            'horometros': '{}',
            'check_list': '[]',
            'condiciones_equipo': '{}',
            'control_llantas': '{}',
          },
          {
            'id': 13,
            'fecha': '2026-06-17',
            'turno': 'DAY',
            'seccion': 'Draft Section',
            'seccion_id': 33,
            'operador': 'Draft Operator',
            'operador_id': null,
            'jefe_guardia': 'Draft Guard',
            'jefe_guardia_id': 43,
            'equipo': 'Draft Equipment',
            'equipo_id': 23,
            'n_equipo': 'TH-03',
            'modelo_equipo': 'S3D',
            'estado': 'cerrado',
            'envio': 0,
            'identity_version': 2,
            'syncable': 0,
            'registros': '[]',
            'horometros': '{}',
            'check_list': '[]',
            'condiciones_equipo': '{}',
            'control_llantas': '{}',
          },
          {
            'id': 14,
            'fecha': '2026-06-17',
            'turno': 'DAY',
            'seccion': 'Legacy Section',
            'seccion_id': null,
            'operador': 'Legacy Operator',
            'operador_id': null,
            'jefe_guardia': 'Legacy Guard',
            'jefe_guardia_id': null,
            'equipo': 'Legacy Equipment',
            'equipo_id': null,
            'n_equipo': 'TH-04',
            'modelo_equipo': 'Legacy',
            'estado': 'cerrado',
            'envio': 0,
            'identity_version': 0,
            'syncable': 1,
            'registros': '[]',
            'horometros': '{}',
            'check_list': '[]',
            'condiciones_equipo': '{}',
            'control_llantas': '{}',
          },
        ],
      );

      expect(jsonData.map((item) => item['local_id']), [12]);
    },
  );
}
