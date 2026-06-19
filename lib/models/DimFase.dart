class DimFase {
  final int faseId;
  final String nombre;
  final String? codigo;
  final String? descripcion;
  final String? estado;

  const DimFase({
    required this.faseId,
    required this.nombre,
    this.codigo,
    this.descripcion,
    this.estado,
  });

  factory DimFase.fromJson(Map<String, dynamic> json) {
    return DimFase(
      faseId: _asInt(json['faseId']) ?? _asInt(json['fase_id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString(),
      descripcion: json['descripcion']?.toString(),
      estado: json['estado']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fase_id': faseId,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'estado': estado,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
