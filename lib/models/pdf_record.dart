class PdfRecord {
  final int id;
  final String proceso;
  final String mes;
  final String urlPdf;
  final String? labor;
  final DateTime createdAt;
  final DateTime updatedAt;

  PdfRecord({
    required this.id,
    required this.proceso,
    required this.mes,
    required this.urlPdf,
    this.labor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PdfRecord.fromJson(Map<String, dynamic> json) {
    return PdfRecord(
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

  static String? _parseLabor(dynamic labor) {
    if (labor == null) return null;
    final laborStr = labor.toString().trim();
    return laborStr.isEmpty ? null : laborStr;
  }
}
