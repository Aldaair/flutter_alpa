class CategoriaEstado {
  final int? id;
  final String nombre;
  final bool activo;

  const CategoriaEstado({this.id, required this.nombre, required this.activo});

  factory CategoriaEstado.fromJson(Map<String, dynamic> json) {
    return CategoriaEstado(
      id: json['id'],
      nombre: json['nombre']?.toString() ?? '',
      activo: _asBool(json['activo']) ?? true,
    );
  }

  factory CategoriaEstado.fromMap(Map<String, dynamic> map) {
    return CategoriaEstado(
      id: map['id'],
      nombre: map['nombre']?.toString() ?? '',
      activo: _asBool(map['activo']) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre, 'activo': activo ? 1 : 0};
  }

  static bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;

    return null;
  }
}
