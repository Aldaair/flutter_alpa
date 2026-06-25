class CategoriaEstado {
  final int? id;
  final String nombre;

  const CategoriaEstado({this.id, required this.nombre});

  factory CategoriaEstado.fromJson(Map<String, dynamic> json) {
    return CategoriaEstado(
      id: json['id'],
      nombre: json['nombre']?.toString() ?? '',
    );
  }

  factory CategoriaEstado.fromMap(Map<String, dynamic> map) {
    return CategoriaEstado(
      id: map['id'],
      nombre: map['nombre']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre};
  }
}
