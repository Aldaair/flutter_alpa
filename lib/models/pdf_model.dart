class PdfModel {
  final String categoria;
  final String fileName;
  final String filePath;

  const PdfModel({
    required this.categoria,
    required this.fileName,
    required this.filePath,
  });

  String get fileExtension => fileName.split('.').last;
}

class PdfCategory {
  final String name;
  final List<PdfModel> files;

  const PdfCategory({required this.name, required this.files});
}
