class DimTurno {
  final int turnoId;
  final String nombre;
  final String? codigo;
  final String? horarioInicio;
  final String? horarioFin;

  const DimTurno({
    required this.turnoId,
    required this.nombre,
    this.codigo,
    this.horarioInicio,
    this.horarioFin,
  });

  factory DimTurno.fromJson(Map<String, dynamic> json) {
    return DimTurno(
      turnoId: _asInt(json['turnoId']) ?? _asInt(json['turno_id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString(),
      horarioInicio: json['horario_inicio']?.toString(),
      horarioFin: json['horario_fin']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'turno_id': turnoId,
      'nombre': nombre,
      'codigo': codigo,
      'horario_inicio': horarioInicio,
      'horario_fin': horarioFin,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
