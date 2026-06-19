class DimPeriodo {
  const DimPeriodo({
    required this.periodoId,
    required this.tipo,
    required this.numero,
    required this.anno,
    required this.fechaInicio,
    required this.fechaFin,
    this.createdAt,
  });

  final int periodoId;
  final String tipo;
  final int numero;
  final int anno;
  final String fechaInicio;
  final String fechaFin;
  final String? createdAt;

  factory DimPeriodo.fromJson(Map<String, dynamic> json) {
    return DimPeriodo(
      periodoId: _asInt(json['periodoId']) ?? _asInt(json['periodo_id']) ?? 0,
      tipo: json['tipo']?.toString() ?? '',
      numero: _asInt(json['numero']) ?? 0,
      anno: _asInt(json['anno']) ?? 0,
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'periodo_id': periodoId,
      'tipo': tipo,
      'numero': numero,
      'anno': anno,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'created_at': createdAt,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
