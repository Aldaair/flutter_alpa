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
  String fechaIngreso; // Se usa String para manejar formato ISO
  double? capacidadYd3;
  double? capacidadM3;

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
  });

  // Convertir de JSON a Objeto
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
    );
  }

  // Convertir de Objeto a Map (para BD local)
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

  static int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
