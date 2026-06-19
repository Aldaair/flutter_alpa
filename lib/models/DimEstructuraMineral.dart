class DimEstructuraMineral {
  final int estructuraMineralId;
  final String nombre;
  final String? codigo;
  final String? caracteristicas;
  final String? estado;

  const DimEstructuraMineral({
    required this.estructuraMineralId,
    required this.nombre,
    this.codigo,
    this.caracteristicas,
    this.estado,
  });

  factory DimEstructuraMineral.fromJson(Map<String, dynamic> json) {
    return DimEstructuraMineral(
      estructuraMineralId: _asInt(json['estructuraMineralId']) ??
          _asInt(json['estructura_mineral_id']) ??
          0,
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString(),
      caracteristicas: json['caracteristicas']?.toString(),
      estado: json['estado']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estructura_mineral_id': estructuraMineralId,
      'nombre': nombre,
      'codigo': codigo,
      'caracteristicas': caracteristicas,
      'estado': estado,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
