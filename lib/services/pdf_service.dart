import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:i_miner/models/pdf_record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';

class PdfService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<PdfRecord>> fetchPdfsPorMes(String token, String mes) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.pdfEndpoint}/mes/$mes';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        print('📥 PDFs recibidos: ${responseData.length}');

        List<PdfRecord> pdfs = responseData
            .map((data) => PdfRecord.fromJson(data))
            .toList();

        await _dbHelper.deleteAll('pdfs');

        await savePdfsToLocalDB(pdfs);

        return pdfs;
      } else {
        throw Exception('Error al cargar PDFs. Código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<void> savePdfsToLocalDB(List<PdfRecord> pdfs) async {
    for (var pdf in pdfs) {
      final localPath = await _downloadPdfAndSaveLocally(pdf);

      if (localPath.isNotEmpty) {
        final pdfData = {
          'id': pdf.id,
          'proceso': pdf.proceso,
          'mes': pdf.mes,
          'url_pdf': localPath,
          'labor': pdf.labor,
          'createdAt': pdf.createdAt.toIso8601String(),
          'updatedAt': pdf.updatedAt.toIso8601String(),
        };

        print('💾 Guardando PDF local: ${jsonEncode(pdfData)}');

        await _dbHelper.insert('pdfs', pdfData);
      } else {
        print('❌ No se pudo descargar el PDF ${pdf.id}');
      }
    }
  }

  Future<String> _downloadPdfAndSaveLocally(PdfRecord pdf) async {
    try {
      final response = await http.get(Uri.parse(pdf.urlPdf));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();

        final pdfDir = Directory('${directory.path}/pdfs');

        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
        }

        final filename = 'pdf_${pdf.id}_${pdf.mes.toLowerCase()}.pdf';

        final filePath = path.join(pdfDir.path, filename);

        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      }

      return '';
    } catch (e) {
      print('❌ Error al guardar PDF local: $e');
      return '';
    }
  }
}
