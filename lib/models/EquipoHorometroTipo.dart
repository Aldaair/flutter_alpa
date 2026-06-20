class EquipoHorometroTipo {
  int equipoId;
  String? equipoNombre;
  int tipoHorometroId;
  String? tipoHorometroNombre;

  EquipoHorometroTipo({
    required this.equipoId,
    this.equipoNombre,
    required this.tipoHorometroId,
    this.tipoHorometroNombre,
  });

  factory EquipoHorometroTipo.fromJson(Map<String, dynamic> json) {
    return EquipoHorometroTipo(
      equipoId: json['equipo_id'],
      equipoNombre: json['equipo_nombre'],
      tipoHorometroId: json['tipo_horometro_id'],
      tipoHorometroNombre: json['tipo_horometro_nombre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipo_id': equipoId,
      'equipo_nombre': equipoNombre,
      'tipo_horometro_id': tipoHorometroId,
      'tipo_horometro_nombre': tipoHorometroNombre,
    };
  }
}
