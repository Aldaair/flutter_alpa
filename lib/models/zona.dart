class Zona {
  int? id;
  String proceso;
  String nombre;
  int? minaId;
  String codigo;
  String estado;
  String? minaNombre;
  String? createdAt;
  String? updatedAt;
  String? createdBy;
  String? updatedBy;

  Zona({
    this.id,
    required this.proceso,
    required this.nombre,
    this.minaId,
    this.codigo = '',
    this.estado = '',
    this.minaNombre,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory Zona.fromJson(Map<String, dynamic> json) {
    return Zona(
      id: _asInt(json['zonaId'] ?? json['zona_id'] ?? json['id']),
      proceso: json['proceso']?.toString() ?? json['mina_id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      minaId: _asInt(json['mina_id']),
      codigo: json['codigo']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      minaNombre: json['mina_nombre']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      createdBy: json['created_by']?.toString(),
      updatedBy: json['updated_by']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zona_id': id,
      'mina_id': minaId,
      'nombre': nombre,
      'codigo': codigo,
      'estado': estado,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }
}
