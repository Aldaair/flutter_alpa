class DimZona {
  final int zonaId;
  final int? minaId;
  final String nombre;
  final String? codigo;
  final String? estado;

  const DimZona({
    required this.zonaId,
    this.minaId,
    required this.nombre,
    this.codigo,
    this.estado,
  });

  factory DimZona.fromJson(Map<String, dynamic> json) {
    return DimZona(
      zonaId: _asInt(json['zonaId']) ?? _asInt(json['zona_id']) ?? 0,
      minaId: _asInt(json['minaId']) ?? _asInt(json['mina_id']),
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString(),
      estado: json['estado']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zona_id': zonaId,
      'mina_id': minaId,
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
