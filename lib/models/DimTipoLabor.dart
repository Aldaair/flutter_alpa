class DimTipoLabor {
  final int tipoLaborId;
  final String nombre;
  final String? codigo;
  final String? descripcion;
  final String? estado;

  const DimTipoLabor({
    required this.tipoLaborId,
    required this.nombre,
    this.codigo,
    this.descripcion,
    this.estado,
  });

  factory DimTipoLabor.fromJson(Map<String, dynamic> json) {
    return DimTipoLabor(
      tipoLaborId:
          _asInt(json['tipoLaborId']) ?? _asInt(json['tipo_labor_id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString(),
      descripcion: json['descripcion']?.toString(),
      estado: json['estado']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo_labor_id': tipoLaborId,
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
