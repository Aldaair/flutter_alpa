import 'dart:convert';

class Equipo {
  int? id;
  int? procesoId;
  String nombre;
  String proceso;
  String codigo;
  String marca;
  String modelo;
  String serie;
  int anioFabricacion;
  String fechaIngreso;
  double? capacidadYd3;
  double? capacidadM3;
  List<Map<String, dynamic>>? horometros;
  Map<String, dynamic>? ultimosHorometros;

  Equipo({
    this.id,
    this.procesoId,
    required this.nombre,
    required this.proceso,
    required this.codigo,
    required this.marca,
    required this.modelo,
    required this.serie,
    required this.anioFabricacion,
    required this.fechaIngreso,
    this.capacidadYd3,
    this.capacidadM3,
    this.horometros,
    this.ultimosHorometros,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: _asInt(json['id']),
      procesoId: _asInt(json['proceso_id']),
      nombre: json['nombre']?.toString() ?? '',
      proceso: json['proceso']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      marca: json['marca']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
      serie: json['serie']?.toString() ?? '',
      anioFabricacion: _asInt(json['anioFabricacion']) ?? 0,
      fechaIngreso: json['fechaIngreso']?.toString() ?? '',
      capacidadYd3: _asDouble(json['capacidadYd3']),
      capacidadM3: _asDouble(json['capacidadM3']),
      horometros: json['horometros'] != null
          ? List<Map<String, dynamic>>.from(json['horometros'])
          : null,
      ultimosHorometros: json['ultimos_horometros'] != null
          ? (json['ultimos_horometros'] is Map
              ? Map<String, dynamic>.from(json['ultimos_horometros'])
              : _tryDecodeJson(json['ultimos_horometros'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proceso_id': procesoId,
      'nombre': nombre,
      'proceso': proceso,
      'codigo': codigo,
      'marca': marca,
      'modelo': modelo,
      'serie': serie,
      'anioFabricacion': anioFabricacion,
      'fechaIngreso': fechaIngreso,
      'capacidadYd3': capacidadYd3,
      'capacidadM3': capacidadM3,
      'ultimos_horometros': ultimosHorometros != null
          ? jsonEncode(ultimosHorometros)
          : null,
    };
  }

  bool matchesProceso(String expected) {
    return _normalizeProceso(proceso) == _normalizeProceso(expected);
  }

  static String _normalizeProceso(String value) {
    const replacements = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'á': 'A',
      'é': 'E',
      'í': 'I',
      'ó': 'O',
      'ú': 'U',
      'ü': 'U',
    };

    final buffer = StringBuffer();
    for (final rune in value.trim().runes) {
      buffer.write(
        replacements[String.fromCharCode(rune)] ?? String.fromCharCode(rune),
      );
    }

    return buffer.toString().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static Map<String, dynamic>? _tryDecodeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
