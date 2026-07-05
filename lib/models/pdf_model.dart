// models/pdf_model.dart
class PdfModel {
  final int id;
  final String proceso;
  final String mes;
  final String urlPdf;
  final String? labor;
  final DateTime createdAt;
  final DateTime updatedAt;

  PdfModel({
    required this.id,
    required this.proceso,
    required this.mes,
    required this.urlPdf,
    this.labor,
    required this.createdAt,
    required this.updatedAt,
  });

  // Constructor vacío para casos especiales
  PdfModel.empty()
    : id = 0,
      proceso = '',
      mes = '',
      urlPdf = '',
      labor = null,
      createdAt = DateTime.now(),
      updatedAt = DateTime.now();

  // From JSON para API
  factory PdfModel.fromJson(Map<String, dynamic> json) {
    return PdfModel(
      id: json['id'] ?? 0,
      proceso: json['proceso'] ?? '',
      mes: json['mes'] ?? '',
      urlPdf: json['url_pdf'] ?? '',
      labor: _parseLabor(json['labor']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // From Map para SQLite
  factory PdfModel.fromMap(Map<String, dynamic> map) {
    return PdfModel(
      id: map['id'] ?? 0,
      proceso: map['proceso'] ?? '',
      mes: map['mes'] ?? '',
      urlPdf: map['url_pdf'] ?? '',
      labor: _parseLabor(map['labor']),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  // Helper para parsear labor
  static String? _parseLabor(dynamic labor) {
    if (labor == null) return null;
    final laborStr = labor.toString().trim();
    return laborStr.isEmpty ? null : laborStr;
  }

  // To Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proceso': proceso,
      'mes': mes,
      'url_pdf': urlPdf,
      'labor': labor,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // To JSON para API
  Map<String, dynamic> toJson() => toMap();

  // Métodos de utilidad
  @override
  String toString() {
    return 'PdfModel(id: $id, proceso: $proceso, mes: $mes, labor: $labor)';
  }

  // Getter para saber si tiene labor
  bool get hasLabor => labor != null && labor!.isNotEmpty;

  // Getter para el nombre del archivo
  String get fileName => urlPdf.split('/').last;

  // Getter para la extensión del archivo
  String get fileExtension => urlPdf.split('.').last;
}

// Extension para listas de PDFs
extension PdfListExtension on List<PdfModel> {
  // Agrupar por proceso
  Map<String, List<PdfModel>> groupByProceso() {
    final Map<String, List<PdfModel>> grouped = {};
    for (var pdf in this) {
      grouped.putIfAbsent(pdf.proceso, () => []).add(pdf);
    }
    return grouped;
  }

  // Filtrar por proceso
  List<PdfModel> filterByProceso(String proceso) {
    return where((pdf) => pdf.proceso == proceso).toList();
  }

  // Filtrar por mes
  List<PdfModel> filterByMes(String mes) {
    return where((pdf) => pdf.mes == mes).toList();
  }

  // Obtener procesos únicos
  List<String> get uniqueProcesos {
    return map((pdf) => pdf.proceso).toSet().toList()..sort();
  }

  // Obtener meses únicos
  List<String> get uniqueMeses {
    return map((pdf) => pdf.mes).toSet().toList()..sort();
  }

  // Contar por proceso
  Map<String, int> countByProceso() {
    final Map<String, int> counts = {};
    for (var pdf in this) {
      counts[pdf.proceso] = (counts[pdf.proceso] ?? 0) + 1;
    }
    return counts;
  }
}
