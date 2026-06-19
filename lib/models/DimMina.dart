class DimMina {
  final int minaId;
  final String nombre;
  final String? codigo;
  final String? ubicacion;
  final String? estado;

  const DimMina({
    required this.minaId,
    required this.nombre,
    this.codigo,
    this.ubicacion,
    this.estado,
  });

  factory DimMina.fromJson(Map<String, dynamic> json) {
    return DimMina(
      minaId: _asInt(json['minaId']) ?? _asInt(json['mina_id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString(),
      ubicacion: json['ubicacion']?.toString(),
      estado: json['estado']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mina_id': minaId,
      'nombre': nombre,
      'codigo': codigo,
      'ubicacion': ubicacion,
      'estado': estado,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
