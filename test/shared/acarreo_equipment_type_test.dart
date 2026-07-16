import 'package:flutter_test/flutter_test.dart';
import 'package:i_miner/shared/acarreo_equipment_type.dart';

void main() {
  group('isAcarreoLocomotoraOperation', () {
    test('returns true when tipo_equipo is locomotora', () {
      expect(
        isAcarreoLocomotoraOperation({
          'tipo_equipo': 'LOCOMOTORA',
          'equipo': 'VOLQUETE 01',
        }),
        isTrue,
      );
    });

    test('falls back to equipo name when tipo_equipo is missing', () {
      expect(
        isAcarreoLocomotoraOperation({'equipo': 'Locomotora CAT 12'}),
        isTrue,
      );
    });

    test('returns false for non locomotora operations', () {
      expect(
        isAcarreoLocomotoraOperation({'tipo_equipo': 'VOLQUETE'}),
        isFalse,
      );
    });
  });
}
