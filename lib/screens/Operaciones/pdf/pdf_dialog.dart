import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

Future<void> showPdfViewer(
  BuildContext context, {
  required String filePath,
  String? title,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return PdfViewerDialog(filePath: filePath, title: title);
    },
  );
}

class PdfViewerDialog extends StatefulWidget {
  final String filePath;
  final String? title;
  final bool fullscreen;
  final int initialRotationTurns;

  const PdfViewerDialog({
    super.key,
    required this.filePath,
    this.title,
    this.fullscreen = false,
    this.initialRotationTurns = 0,
  });

  @override
  State<PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends State<PdfViewerDialog> {
  late final PdfViewerController _pdfController;
  late int _rotationTurns;
  bool _isSaving = false;

  bool get _fileExists => File(widget.filePath).existsSync();

  String get _resolvedTitle {
    final providedTitle = widget.title?.trim();
    if (providedTitle != null && providedTitle.isNotEmpty) {
      return providedTitle;
    }
    return path.basename(widget.filePath);
  }

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _rotationTurns = widget.initialRotationTurns % 4;
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            _resolvedTitle,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: const Color(0xFF1B5E6B),
          foregroundColor: Colors.white,
          actions: _buildActions(context),
        ),
        body: _buildViewerContent(),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: screenWidth * 0.92,
        height: screenHeight * 0.82,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(color: Color(0xFFF8FBFC)),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFF1B5E6B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _resolvedTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ..._buildActions(context),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildViewerContent()),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Descargar PDF',
        onPressed: _isSaving ? null : _downloadPdf,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined),
      ),
      IconButton(
        tooltip: 'Girar PDF',
        onPressed: _fileExists ? _rotatePdf : null,
        icon: const Icon(Icons.screen_rotation_alt_outlined),
      ),
      IconButton(
        tooltip: widget.fullscreen
            ? 'Salir de pantalla completa'
            : 'Pantalla completa',
        onPressed: () => _toggleFullscreen(context),
        icon: Icon(
          widget.fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
        ),
      ),
      IconButton(
        tooltip: 'Cerrar',
        onPressed: () => Navigator.of(context).pop(_rotationTurns),
        icon: const Icon(Icons.close),
      ),
    ];
  }

  Widget _buildViewerContent() {
    if (!_fileExists) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el PDF',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Archivo no encontrado',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final viewer = SfPdfViewer.file(
      File(widget.filePath),
      controller: _pdfController,
      canShowPaginationDialog: true,
      canShowScrollHead: true,
      enableDoubleTapZooming: true,
    );

    return Container(
      color: widget.fullscreen ? Colors.black : Colors.grey[100],
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: _rotationTurns,
        child: viewer,
      ),
    );
  }

  void _rotatePdf() {
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
  }

  Future<void> _toggleFullscreen(BuildContext context) async {
    if (widget.fullscreen) {
      Navigator.of(context).pop(_rotationTurns);
      return;
    }

    final updatedRotation = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => PdfViewerDialog(
          filePath: widget.filePath,
          title: widget.title,
          fullscreen: true,
          initialRotationTurns: _rotationTurns,
        ),
      ),
    );

    if (!mounted || updatedRotation == null) {
      return;
    }

    setState(() {
      _rotationTurns = updatedRotation % 4;
    });
  }

  Future<void> _downloadPdf() async {
    if (!_fileExists) {
      _showMessage('El archivo ya no existe en el dispositivo.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final sourceFile = File(widget.filePath);
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar PDF',
        fileName: _suggestedFileName(),
      );

      if (outputPath == null || outputPath.trim().isEmpty) {
        return;
      }

      final normalizedPath = outputPath.toLowerCase().endsWith('.pdf')
          ? outputPath
          : '$outputPath.pdf';

      await sourceFile.copy(normalizedPath);

      if (!mounted) {
        return;
      }

      _showMessage('PDF guardado en: $normalizedPath');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('No se pudo guardar el PDF: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _suggestedFileName() {
    final fileName = path.basename(widget.filePath);
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return fileName;
    }
    return '$fileName.pdf';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF1B5E6B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
