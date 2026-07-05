// widgets/pdf_dialog.dart
import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/pdf_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';

Future<void> showPdfDialog(
  BuildContext context, {
  required String tipoOperacion,
  String? tipoLabor,
  String? labor,
  String? ala,
}) async {
  final dbHelper = DatabaseHelper();

  print('📄 Buscando PDF con los siguientes filtros:');
  print('🛠️ Proceso: $tipoOperacion');
  print('🔧 Tipo labor: ${tipoLabor ?? "null"}');
  print('🔨 Labor: ${labor ?? "null"}');
  print('🕊️ Ala: ${ala?.isEmpty ?? true ? "vacío o null" : ala}');

  // Buscar el PDF - ahora retorna PdfModel?
  final PdfModel? pdfData = await dbHelper.getPdfByProceso(
    proceso: tipoOperacion,
    tipoLabor: tipoLabor,
    labor: labor,
    ala: ala,
  );

  // Mostrar consola
  if (pdfData != null) {
    print(
      "✅ PDF encontrado: ${pdfData.urlPdf}",
    ); // Usar .urlPdf en lugar de ['url_pdf']
  } else {
    print("❌ No se encontró ningún PDF con los filtros aplicados.");
  }

  // Obtener la ruta del PDF
  final String? pdfPath = pdfData?.urlPdf; // Usar .urlPdf
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Color(0xFF1B5E6B)),
            const SizedBox(width: 8),
            Text(
              tipoOperacion,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: screenWidth * 0.9,
          height: screenHeight * 0.7,
          child: pdfPath != null && File(pdfPath).existsSync()
              ? SfPdfViewer.file(File(pdfPath))
              : _buildErrorContent(tipoOperacion, tipoLabor, labor, ala),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Color(0xFF1B5E6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildErrorContent(
  String tipoOperacion,
  String? tipoLabor,
  String? labor,
  String? ala,
) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
      const SizedBox(height: 16),
      const Text(
        'No se pudo cargar el PDF',
        style: TextStyle(
          color: Color(0xFF1B5E6B),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _buildFilterItem('Proceso', tipoOperacion),
            if (tipoLabor != null) _buildFilterItem('Tipo Labor', tipoLabor),
            if (labor != null) _buildFilterItem('Labor', labor),
            if (ala != null) _buildFilterItem('Ala', ala),
          ],
        ),
      ),
    ],
  );
}

Widget _buildFilterItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Color(0xFF1B5E6B),
          ),
        ),
      ],
    ),
  );
}
