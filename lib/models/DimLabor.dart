class DimLabor {
  final int laborId;
  final int? minaId;
  final int? zonaId;
  final int? areaId;
  final int? faseId;
  final int? tipoLaborId;
  final int? estructuraMineralId;
  final int? nivelId;
  final int? alaId;
  final String nombreLabor;
  final String? estado;
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
  final String? createdBy;
  final String? updatedBy;

  const DimLabor({
    required this.laborId,
    this.minaId,
    this.zonaId,
    this.areaId,
    this.faseId,
    this.tipoLaborId,
    this.estructuraMineralId,
    this.nivelId,
    this.alaId,
    required this.nombreLabor,
    this.estado,
    this.minaNombre = '',
    this.zonaNombre = '',
    this.areaNombre = '',
    this.faseNombre = '',
    this.tipoLaborNombre = '',
    this.estructuraMineralNombre = '',
    this.nivelNombre = '',
    this.alaNombre = '',
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory DimLabor.fromJson(Map<String, dynamic> json) {
    return DimLabor(
      laborId: _asInt(json['laborId']) ?? _asInt(json['labor_id']) ?? 0,
      minaId: _asInt(json['minaId']) ?? _asInt(json['mina_id']),
      zonaId: _asInt(json['zonaId']) ?? _asInt(json['zona_id']),
      areaId: _asInt(json['areaId']) ?? _asInt(json['area_id']),
      faseId: _asInt(json['faseId']) ?? _asInt(json['fase_id']),
      tipoLaborId:
          _asInt(json['tipoLaborId']) ?? _asInt(json['tipo_labor_id']),
      estructuraMineralId: _asInt(json['estructuraMineralId']) ??
          _asInt(json['estructura_mineral_id']),
      nivelId: _asInt(json['nivelId']) ?? _asInt(json['nivel_id']),
      alaId: _asInt(json['alaId']) ?? _asInt(json['ala_id']),
      nombreLabor: json['nombre_labor']?.toString() ?? '',
      estado: json['estado']?.toString(),
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
      createdBy: json['created_by']?.toString(),
      updatedBy: json['updated_by']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'labor_id': laborId,
      'mina_id': minaId,
      'zona_id': zonaId,
      'area_id': areaId,
      'fase_id': faseId,
      'tipo_labor_id': tipoLaborId,
      'estructura_mineral_id': estructuraMineralId,
      'nivel_id': nivelId,
      'ala_id': alaId,
      'nombre_labor': nombreLabor,
      'estado': estado,
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
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
