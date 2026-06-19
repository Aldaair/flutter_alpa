class JefeGuardia {
  final int id;
  final String nombres;
  final String apellidos;

  JefeGuardia({
    required this.id,
    required this.nombres,
    required this.apellidos,
  });

  factory JefeGuardia.fromJson(Map<String, dynamic> json) {
    return JefeGuardia(
      id: json['id'],
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombres': nombres, 'apellidos': apellidos};
  }
}
