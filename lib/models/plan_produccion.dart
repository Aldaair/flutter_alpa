class PlanProduccion {
  const PlanProduccion({
    required this.planProduccionId,
    required this.laborId,
    required this.periodoId,
    required this.anchoVetaMetros,
    required this.anchoMinadoSemMetros,
    required this.anchoMinadoMesMetros,
    required this.agGr,
    required this.porcentajeCu,
    required this.porcentajePb,
    required this.porcentajeZn,
    required this.vptActual,
    required this.vptFinal,
    required this.cutOff1,
    required this.cutOff2,
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

  final int planProduccionId;
  final int laborId;
  final int periodoId;
  final double anchoVetaMetros;
  final double anchoMinadoSemMetros;
  final double anchoMinadoMesMetros;
  final double agGr;
  final double porcentajeCu;
  final double porcentajePb;
  final double porcentajeZn;
  final double vptActual;
  final double vptFinal;
  final double cutOff1;
  final double cutOff2;
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

  factory PlanProduccion.fromJson(Map<String, dynamic> json) {
    return PlanProduccion(
      planProduccionId:
          _asInt(json['planProduccionId']) ??
          _asInt(json['plan_produccion_id']) ??
          0,
      laborId: _asInt(json['labor_id']) ?? 0,
      periodoId: _asInt(json['periodo_id']) ?? 0,
      anchoVetaMetros: _asDouble(json['ancho_veta_metros']) ?? 0,
      anchoMinadoSemMetros: _asDouble(json['ancho_minado_sem_metros']) ?? 0,
      anchoMinadoMesMetros: _asDouble(json['ancho_minado_mes_metros']) ?? 0,
      agGr: _asDouble(json['ag_gr']) ?? 0,
      porcentajeCu: _asDouble(json['porcentaje_cu']) ?? 0,
      porcentajePb: _asDouble(json['porcentaje_pb']) ?? 0,
      porcentajeZn: _asDouble(json['porcentaje_zn']) ?? 0,
      vptActual: _asDouble(json['vpt_actual']) ?? 0,
      vptFinal: _asDouble(json['vpt_final']) ?? 0,
      cutOff1: _asDouble(json['cut_off_1']) ?? 0,
      cutOff2: _asDouble(json['cut_off_2']) ?? 0,
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
      'plan_produccion_id': planProduccionId,
      'labor_id': laborId,
      'periodo_id': periodoId,
      'ancho_veta_metros': anchoVetaMetros,
      'ancho_minado_sem_metros': anchoMinadoSemMetros,
      'ancho_minado_mes_metros': anchoMinadoMesMetros,
      'ag_gr': agGr,
      'porcentaje_cu': porcentajeCu,
      'porcentaje_pb': porcentajePb,
      'porcentaje_zn': porcentajeZn,
      'vpt_actual': vptActual,
      'vpt_final': vptFinal,
      'cut_off_1': cutOff1,
      'cut_off_2': cutOff2,
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
