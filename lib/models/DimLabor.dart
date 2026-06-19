class DimLabor {
  final int laborId;
  final int? minaId;
  final int? zonaId;
  final int? areaId;
  final int? faseId;
  final int? tipoLaborId;
  final int? estructuraMineralId;
  final int? nivelId;
  final String nombreLabor;
  final String? estado;

  const DimLabor({
    required this.laborId,
    this.minaId,
    this.zonaId,
    this.areaId,
    this.faseId,
    this.tipoLaborId,
    this.estructuraMineralId,
    this.nivelId,
    required this.nombreLabor,
    this.estado,
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
      nombreLabor: json['nombre_labor']?.toString() ?? '',
      estado: json['estado']?.toString(),
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
      'nombre_labor': nombreLabor,
      'estado': estado,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
