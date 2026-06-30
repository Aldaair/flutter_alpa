class PlanAvanceTH {
  const PlanAvanceTH({
    required this.planAvanceThId,
    required this.laborId,
    required this.periodoId,
    required this.avanceMetros,
    required this.anchoMetros,
    required this.altoMetros,
    required this.tms,
    required this.minaId,
    required this.zonaId,
    required this.areaId,
    required this.faseId,
    required this.tipoLaborId,
    required this.estructuraMineralId,
    required this.nivelId,
    required this.alaId,
    required this.laborNombre,
    required this.minaNombre,
    required this.zonaNombre,
    required this.areaNombre,
    required this.faseNombre,
    required this.tipoLaborNombre,
    required this.estructuraMineralNombre,
    required this.nivelNombre,
    required this.alaNombre,
    required this.createdAt,
    required this.updatedAt,
  });

  final int planAvanceThId;
  final int laborId;
  final int periodoId;
  final double avanceMetros;
  final double anchoMetros;
  final double altoMetros;
  final double tms;
  final int minaId;
  final int zonaId;
  final int areaId;
  final int faseId;
  final int tipoLaborId;
  final int estructuraMineralId;
  final int nivelId;
  final int alaId;
  final String laborNombre;
  final String minaNombre;
  final String zonaNombre;
  final String areaNombre;
  final String faseNombre;
  final String tipoLaborNombre;
  final String estructuraMineralNombre;
  final String nivelNombre;
  final String alaNombre;
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
      avanceMetros: _asDouble(json['avance_metros']) ?? 0,
      anchoMetros: _asDouble(json['ancho_metros']) ?? 0,
      altoMetros: _asDouble(json['alto_metros']) ?? 0,
      tms: _asDouble(json['tms']) ?? 0,
      minaId: _asInt(json['mina_id']) ?? 0,
      zonaId: _asInt(json['zona_id']) ?? 0,
      areaId: _asInt(json['area_id']) ?? 0,
      faseId: _asInt(json['fase_id']) ?? 0,
      tipoLaborId: _asInt(json['tipo_labor_id']) ?? 0,
      estructuraMineralId: _asInt(json['estructura_mineral_id']) ?? 0,
      nivelId: _asInt(json['nivel_id']) ?? 0,
      alaId: _asInt(json['ala_id']) ?? 0,
      laborNombre: json['labor_nombre']?.toString() ?? '',
      minaNombre: json['mina_nombre']?.toString() ?? '',
      zonaNombre: json['zona_nombre']?.toString() ?? '',
      areaNombre: json['area_nombre']?.toString() ?? '',
      faseNombre: json['fase_nombre']?.toString() ?? '',
      tipoLaborNombre: json['tipo_labor_nombre']?.toString() ?? '',
      estructuraMineralNombre:
          json['estructura_mineral_nombre']?.toString() ?? '',
      nivelNombre: json['nivel_nombre']?.toString() ?? '',
      alaNombre: json['ala_nombre']?.toString() ?? '',
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan_metraje_avance_id': planAvanceThId,
      'labor_id': laborId,
      'periodo_id': periodoId,
      'avance_metros': avanceMetros,
      'ancho_metros': anchoMetros,
      'alto_metros': altoMetros,
      'tms': tms,
      'mina_id': minaId,
      'zona_id': zonaId,
      'area_id': areaId,
      'fase_id': faseId,
      'tipo_labor_id': tipoLaborId,
      'estructura_mineral_id': estructuraMineralId,
      'nivel_id': nivelId,
      'ala_id': alaId,
      'labor_nombre': laborNombre,
      'mina_nombre': minaNombre,
      'zona_nombre': zonaNombre,
      'area_nombre': areaNombre,
      'fase_nombre': faseNombre,
      'tipo_labor_nombre': tipoLaborNombre,
      'estructura_mineral_nombre': estructuraMineralNombre,
      'nivel_nombre': nivelNombre,
      'ala_nombre': alaNombre,
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
