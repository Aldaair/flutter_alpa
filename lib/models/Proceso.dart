class Proceso {
  final int id;
  final String nombre;
  final String? nombreAbreviado;

  Proceso({
    required this.id,
    required this.nombre,
    this.nombreAbreviado,
  });

  factory Proceso.fromJson(Map<String, dynamic> json) {
    return Proceso(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      nombreAbreviado: json['nombre_abreviado'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'nombre_abreviado': nombreAbreviado,
    };
  }
}
