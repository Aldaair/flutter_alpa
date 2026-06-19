import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:i_miner/services/user_service.dart';

void main() {
  test('getUserProfile returns profile when operador_id is present', () async {
    final service = UserService(
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://example.com/usuarios/perfil');
        expect(request.headers['Authorization'], 'Bearer token');

        return http.Response(
          jsonEncode({
            'codigo_dni': '12345678',
            'operador_id': 44,
            'apellidos': 'Perez',
            'nombres': 'Ana',
            'procesos': [],
            'usuario_procesos': [],
            'usuario_equipos': [],
          }),
          200,
        );
      }),
      baseUrl: 'https://example.com',
    );

    final profile = await service.getUserProfile('token');

    expect(profile['operador_id'], 44);
    expect(profile['codigo_dni'], '12345678');
  });

  test('getUserProfile normalizes offline authorization payload', () async {
    final service = UserService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'codigo_dni': '12345678',
            'operador_id': '44',
            'apellidos': 'Perez',
            'nombres': 'Ana',
            'procesos': [
              {'id': '7', 'nombre': 'Taladro Horizontal'},
              {'id': 8, 'nombre': 'Dashboard'},
            ],
            'usuario_procesos': [
              {'codigo_dni': '12345678', 'proceso_id': '7'},
              {'codigo_dni': '12345678', 'proceso_id': 8},
            ],
            'usuario_equipos': [
              {
                'codigo_dni': '12345678',
                'proceso_id': '7',
                'equipo_id': '100',
              },
            ],
          }),
          200,
        );
      }),
      baseUrl: 'https://example.com',
    );

    final profile = await service.getUserProfile('token');
    final normalizedAuth =
        profile['normalized_authorization'] as Map<String, dynamic>;

    expect(profile['operador_id'], 44);
    expect(normalizedAuth['procesos'], [
      {'id': 7, 'nombre': 'Taladro Horizontal'},
      {'id': 8, 'nombre': 'Dashboard'},
    ]);
    expect(normalizedAuth['usuario_procesos'], [
      {'codigo_dni': '12345678', 'proceso_id': 7},
      {'codigo_dni': '12345678', 'proceso_id': 8},
    ]);
    expect(normalizedAuth['usuario_equipos'], [
      {'codigo_dni': '12345678', 'proceso_id': 7, 'equipo_id': 100},
    ]);
  });

  test('getUserProfile throws when operador_id is missing', () async {
    final service = UserService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'codigo_dni': '12345678',
            'apellidos': 'Perez',
            'nombres': 'Ana',
          }),
          200,
        );
      }),
      baseUrl: 'https://example.com',
    );

    await expectLater(
      service.getUserProfile('token'),
      throwsA(
        isA<UserProfileContractException>().having(
          (error) => error.message,
          'message',
          contains('operador_id'),
        ),
      ),
    );
  });

  test('getUserProfile throws when normalized auth payload is missing', () async {
    final service = UserService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'codigo_dni': '12345678',
            'operador_id': 44,
            'apellidos': 'Perez',
            'nombres': 'Ana',
            'procesos': [],
            'usuario_procesos': [],
          }),
          200,
        );
      }),
      baseUrl: 'https://example.com',
    );

    await expectLater(
      service.getUserProfile('token'),
      throwsA(
        isA<UserProfileContractException>().having(
          (error) => error.message,
          'message',
          contains('usuario_equipos'),
        ),
      ),
    );
  });

  test('getUserProfile throws when normalized auth payload has invalid ids', () async {
    final service = UserService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'codigo_dni': '12345678',
            'operador_id': 44,
            'apellidos': 'Perez',
            'nombres': 'Ana',
            'procesos': [
              {'id': 'bad-id', 'nombre': 'Taladro Horizontal'},
            ],
            'usuario_procesos': [
              {'codigo_dni': '12345678', 'proceso_id': 7},
            ],
            'usuario_equipos': [
              {'codigo_dni': '12345678', 'proceso_id': 7, 'equipo_id': 100},
            ],
          }),
          200,
        );
      }),
      baseUrl: 'https://example.com',
    );

    await expectLater(
      service.getUserProfile('token'),
      throwsA(
        isA<UserProfileContractException>().having(
          (error) => error.message,
          'message',
          contains('procesos[0].id'),
        ),
      ),
    );
  });
}
