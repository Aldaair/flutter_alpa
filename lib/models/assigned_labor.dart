class AssignedLabor {
  const AssignedLabor({
    required this.laborId,
    required this.laborNombre,
    required this.estructuraMineral,
    required this.nivel,
    required this.ala,
    required this.tipoLabor,
    required this.valorPlanificado,
  });

  final int laborId;
  final String laborNombre;
  final String estructuraMineral;
  final String nivel;
  final String ala;
  final String tipoLabor;
  final double valorPlanificado;

  factory AssignedLabor.fromJson(Map<String, dynamic> json) {
    return AssignedLabor(
      laborId: _asInt(json['labor_id']) ?? 0,
      laborNombre: json['labor_nombre']?.toString() ?? '',
      estructuraMineral: json['estructura_mineral']?.toString() ?? '',
      nivel: json['nivel']?.toString() ?? '',
      ala: json['ala']?.toString() ?? '',
      tipoLabor: json['tipo_labor']?.toString() ?? '',
      valorPlanificado: _asDouble(json['valor_planificado']) ?? 0,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
