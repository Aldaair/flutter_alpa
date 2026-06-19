class DimNivel {
  final int nivelId;
  final String nombre;
  final int? numero;
  final double? profundidadPromedio;
  final String? estado;

  const DimNivel({
    required this.nivelId,
    required this.nombre,
    this.numero,
    this.profundidadPromedio,
    this.estado,
  });

  factory DimNivel.fromJson(Map<String, dynamic> json) {
    return DimNivel(
      nivelId: _asInt(json['nivelId']) ?? _asInt(json['nivel_id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      numero: _asInt(json['numero']),
      profundidadPromedio: _asDouble(json['profundidad_promedio']),
      estado: json['estado']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nivel_id': nivelId,
      'nombre': nombre,
      'numero': numero,
      'profundidad_promedio': profundidadPromedio,
      'estado': estado,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
