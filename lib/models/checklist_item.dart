class CheckListItem {
  int? id;
  int? procesoId;
  String proceso;
  int? categoriaId;
  String categoria;
  String nombre;
  int? orden;
  int? categoriaOrden;

  CheckListItem({
    this.id,
    this.procesoId,
    required this.proceso,
    this.categoriaId,
    required this.categoria,
    required this.nombre,
    this.orden,
    this.categoriaOrden,
  });

  factory CheckListItem.fromJson(Map<String, dynamic> json) {
    return CheckListItem(
      id: _asInt(json['id']),
      procesoId: _asInt(json['proceso_id']),
      proceso: json['proceso']?.toString() ?? '',
      categoriaId: _asInt(json['categoria_id']),
      categoria: json['categoria']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      orden: _asInt(json['orden']),
      categoriaOrden: _asInt(json['categoria_orden']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proceso_id': procesoId,
      'proceso': proceso,
      'categoria_id': categoriaId,
      'categoria': categoria,
      'nombre': nombre,
      'orden': orden,
      'categoria_orden': categoriaOrden,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
