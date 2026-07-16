class Destino {
  const Destino({
    this.id,
    this.proceso,
    required this.nombre,
    required this.procesoId,
    this.tipo,
    this.tipoEquipo,
  });

  final int? id;
  final String? proceso;
  final String nombre;
  final int procesoId;
  final String? tipo;
  final String? tipoEquipo;

  factory Destino.fromJson(Map<String, dynamic> json) {
    return Destino(
      id: _asInt(json['id']),
      proceso: json['proceso']?.toString(),
      nombre: json['nombre']?.toString() ?? '',
      procesoId: _asInt(json['proceso_id']) ?? 0,
      tipo: json['tipo']?.toString(),
      tipoEquipo: json['tipo_equipo']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proceso': proceso,
      'nombre': nombre,
      'proceso_id': procesoId,
      'tipo': tipo,
      'tipo_equipo': tipoEquipo,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
