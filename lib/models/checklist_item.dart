class CheckListItem {
  int? id;
  int? procesoId;
  String proceso;
  String categoria;
  String nombre;
  int? orden;

  CheckListItem({
    this.id,
    this.procesoId,
    required this.proceso,
    required this.categoria,
    required this.nombre,
    this.orden,
  });

  factory CheckListItem.fromJson(Map<String, dynamic> json) {
    return CheckListItem(
      id: _asInt(json['id']),
      procesoId: _asInt(json['proceso_id']),
      proceso: json['proceso']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      orden: _asInt(json['orden']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proceso_id': procesoId,
      'proceso': proceso,
      'categoria': categoria,
      'nombre': nombre,
      'orden': orden,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
