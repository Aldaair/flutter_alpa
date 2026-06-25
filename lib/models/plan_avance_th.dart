class PlanAvanceTH {
  const PlanAvanceTH({
    required this.planAvanceThId,
    required this.laborId,
    required this.periodoId,
    required this.turnoId,
    required this.leyId,
    required this.procesoId,
    required this.procesoNombre,
    required this.dia,
    required this.valor,
    required this.laborNombre,
    required this.turnoNombre,
    required this.leyNombre,
    required this.createdAt,
    required this.updatedAt,
  });

  final int planAvanceThId;
  final int laborId;
  final int periodoId;
  final int turnoId;
  final int leyId;
  final int procesoId;
  final String procesoNombre;
  final int dia;
  final double valor;
  final String laborNombre;
  final String turnoNombre;
  final String leyNombre;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PlanAvanceTH.fromJson(Map<String, dynamic> json) {
    return PlanAvanceTH(
      planAvanceThId:
          _asInt(json['planMetrajeAvanceId']) ??
          _asInt(json['plan_metraje_avance_id']) ??
          0,
      laborId: _asInt(json['labor_id']) ?? 0,
      periodoId: _asInt(json['periodo_id']) ?? 0,
      turnoId: _asInt(json['turno_id']) ?? 0,
      leyId: _asInt(json['ley_id']) ?? 0,
      procesoId: _asInt(json['proceso_id']) ?? 0,
      procesoNombre: json['proceso_nombre']?.toString() ?? '',
      dia: _asInt(json['dia']) ?? 0,
      valor: _asDouble(json['valor']) ?? 0,
      laborNombre: json['labor_nombre']?.toString() ?? '',
      turnoNombre: json['turno_nombre']?.toString() ?? '',
      leyNombre: json['ley_nombre']?.toString() ?? '',
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan_metraje_avance_id': planAvanceThId,
      'labor_id': laborId,
      'periodo_id': periodoId,
      'turno_id': turnoId,
      'ley_id': leyId,
      'proceso_id': procesoId,
      'proceso_nombre': procesoNombre,
      'dia': dia,
      'valor': valor,
      'labor_nombre': laborNombre,
      'turno_nombre': turnoNombre,
      'ley_nombre': leyNombre,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
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

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
