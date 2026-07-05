import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/models/pdf_model.dart';
import 'package:i_miner/services/api_service.dart';

class PdfSyncService {
  static const String _pdfRootDirName = 'pdfs_pdf';

  static final PdfSyncService _instance = PdfSyncService._();
  factory PdfSyncService() => _instance;
  PdfSyncService._();

  Future<String> get _pdfRootPath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _pdfRootDirName);
  }

  Future<bool> isSynced() async {
    final rootPath = await _pdfRootPath;
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return false;
    final entities = await rootDir.list().toList();
    return entities.isNotEmpty;
  }

  Future<void> clearSync() async {
    final rootPath = await _pdfRootPath;
    final rootDir = Directory(rootPath);
    if (await rootDir.exists()) {
      await rootDir.delete(recursive: true);
    }
  }

  Future<void> syncAll() async {
    await _downloadAndExtract(categoria: null);
  }

  Future<void> syncCategory(String categoria) async {
    await _downloadAndExtract(categoria: categoria);
  }

  Future<void> _downloadAndExtract({String? categoria}) async {
    final apiService = ApiService();
    final token = await apiService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.pdfDownloadAllEndpoint}',
    ).replace(queryParameters: {
      if (categoria != null) 'categoria': categoria,
    });

    print('📡 PDF sync URL: $uri');
    print('🔑 Token: ${token.length > 10 ? "${token.substring(0, 10)}..." : "invalido"}');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    print('📥 PDF sync status: ${response.statusCode}');
    print('📥 PDF sync body: ${response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body}');

    if (response.statusCode == 401) {
      throw Exception(
        'Token inválido o expirado. Cierra sesión y vuelve a iniciar.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception('Error al descargar ZIP. Código: ${response.statusCode}');
    }

    final bytes = response.bodyBytes;
    final archive = ZipDecoder().decodeBytes(bytes);

    final rootPath = await _pdfRootPath;

    for (final entry in archive) {
      if (entry.isFile) {
        final filePath = p.join(rootPath, entry.name);
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content);
      }
    }
  }

  Future<List<PdfCategory>> getCategories() async {
    final rootPath = await _pdfRootPath;
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return [];

    final categories = <PdfCategory>[];
    await for (final entity in rootDir.list()) {
      if (entity is Directory) {
        final categoryName = p.basename(entity.path);
        final files = await entity.list().toList();
        final pdfFiles = files
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.pdf'))
            .map(
              (f) => PdfModel(
                categoria: categoryName,
                fileName: p.basename(f.path),
                filePath: f.path,
              ),
            )
            .toList();
        pdfFiles.sort((a, b) => a.fileName.compareTo(b.fileName));
        categories.add(PdfCategory(name: categoryName, files: pdfFiles));
      }
    }

    const knownOrder = ['ESTANDARES', 'PROCEDIMIENTOS', 'PLANOS'];
    categories.sort((a, b) {
      final ai = knownOrder.indexOf(a.name);
      final bi = knownOrder.indexOf(b.name);
      if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
      if (ai >= 0) return -1;
      if (bi >= 0) return 1;
      return a.name.compareTo(b.name);
    });

    return categories;
  }
}
