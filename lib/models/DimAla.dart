class DimAla {
  final int alaId;
  final String nombre;
  final String? codigo;
  final int? orden;
  final String? estado;

  const DimAla({
    required this.alaId,
    required this.nombre,
    this.codigo,
    this.orden,
    this.estado,
  });

  factory DimAla.fromJson(Map<String, dynamic> json) {
    return DimAla(
      alaId: _asInt(json['alaId']) ?? _asInt(json['ala_id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString(),
      orden: _asInt(json['orden']),
      estado: json['estado']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ala_id': alaId,
      'nombre': nombre,
      'codigo': codigo,
      'orden': orden,
      'estado': estado,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
