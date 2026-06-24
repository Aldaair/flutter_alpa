class Cargo {
  final int cargoId;
  final String nombre;

  Cargo({required this.cargoId, required this.nombre});

  factory Cargo.fromJson(Map<String, dynamic> json) {
    return Cargo(cargoId: json['id'] as int, nombre: json['nombre'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'cargo_id': cargoId, 'nombre': nombre};
  }
}
