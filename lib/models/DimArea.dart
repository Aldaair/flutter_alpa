class DimArea {
  final int areaId;
  final int? zonaId;
  final String nombre;
  final String? codigo;
  final String? estado;

  const DimArea({
    required this.areaId,
    this.zonaId,
    required this.nombre,
    this.codigo,
    this.estado,
  });

  factory DimArea.fromJson(Map<String, dynamic> json) {
    return DimArea(
      areaId: _asInt(json['areaId']) ?? _asInt(json['area_id']) ?? 0,
      zonaId: _asInt(json['zonaId']) ?? _asInt(json['zona_id']),
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString(),
      estado: json['estado']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'area_id': areaId,
      'zona_id': zonaId,
      'nombre': nombre,
      'codigo': codigo,
      'estado': estado,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
