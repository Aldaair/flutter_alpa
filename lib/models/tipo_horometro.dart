class TipoHorometro {
  int? id;
  String nombre;

  TipoHorometro({this.id, required this.nombre});

  factory TipoHorometro.fromJson(Map<String, dynamic> json) {
    return TipoHorometro(id: json['id'], nombre: json['nombre']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre};
  }
}
