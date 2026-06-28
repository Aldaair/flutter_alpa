class TipoPerforacion {
  int? id;
  String nombre;
  String? proceso;
  int? procesoId;
  int permitidoMedicion;

  TipoPerforacion({
    this.id,
    required this.nombre,
    this.proceso,
    this.procesoId,
    this.permitidoMedicion = 0,
  });

  factory TipoPerforacion.fromJson(Map<String, dynamic> json) {
    return TipoPerforacion(
      id: json['id'],
      nombre: json['nombre'],
      proceso: json['proceso'],
      procesoId: json['proceso_id'],
      permitidoMedicion: json['permitido_medicion'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'proceso': proceso,
      'proceso_id': procesoId,
      'permitido_medicion': permitidoMedicion,
    };
  }
}
