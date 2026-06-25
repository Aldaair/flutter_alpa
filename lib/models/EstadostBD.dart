class EstadostBD {
  int? id;
  String codigo;
  String tipoEstado;
  String categoria;
  String proceso;
  int? procesoId;
  int? categoriaId;

  EstadostBD({
    this.id,
    required this.codigo,
    required this.tipoEstado,
    required this.categoria,
    required this.proceso,
    this.procesoId,
    this.categoriaId,
  });

  factory EstadostBD.fromMap(Map<String, dynamic> map) {
    return EstadostBD(
      id: map['id'],
      codigo: map['codigo'],
      tipoEstado: map['tipo_estado'],
      categoria: map['categoria'],
      proceso: map['proceso'],
      procesoId: map['proceso_id'],
      categoriaId: map['categoria_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'tipo_estado': tipoEstado,
      'categoria': categoria,
      'proceso': proceso,
      'proceso_id': procesoId,
      'categoria_id': categoriaId,
    };
  }

  factory EstadostBD.fromJson(Map<String, dynamic> json) {
    return EstadostBD(
      id: json['id'],
      codigo: json['codigo'],
      tipoEstado: json['tipo_estado'],
      categoria: json['categoria'],
      proceso: json['proceso'],
      procesoId: json['proceso_id'],
      categoriaId: json['categoria_id'],
    );
  }
}
