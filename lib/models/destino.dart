class Destino {
  const Destino({this.id, required this.nombre, required this.procesoId});

  final int? id;
  final String nombre;
  final int procesoId;

  factory Destino.fromJson(Map<String, dynamic> json) {
    return Destino(
      id: _asInt(json['id']),
      nombre: json['nombre']?.toString() ?? '',
      procesoId: _asInt(json['proceso_id']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre, 'proceso_id': procesoId};
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
