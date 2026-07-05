// screens/pdf_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:i_miner/models/pdf_model.dart';
import 'package:i_miner/screens/Operaciones/pdf/pdf_dialog.dart';

class PdfDetailScreen extends StatelessWidget {
  final String proceso;
  final List<PdfModel> pdfs;

  const PdfDetailScreen({super.key, required this.proceso, required this.pdfs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          proceso,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1B5E6B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: pdfs.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildCompactHeader(),
                Expanded(child: _buildPdfList()),
              ],
            ),
    );
  }

  // HEADER COMPACTO
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.description, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${pdfs.length} documentos',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E6B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${pdfs.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LISTA DE PDFs - MÁS COMPACTA
  Widget _buildPdfList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        return _buildPdfCardCompact(context, pdf);
      },
    );
  }

  // CARD COMPACTA
  Widget _buildPdfCardCompact(BuildContext context, PdfModel pdf) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          showPdfDialog(context, tipoOperacion: pdf.proceso, labor: pdf.labor);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Icono PDF
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E6B).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Color(0xFF1B5E6B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.labor ?? 'Sin labor',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E6B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 11,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pdf.mes,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.folder_outlined,
                          size: 11,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pdf.proceso,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botón ver
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E6B).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: Color(0xFF1B5E6B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ver',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ESTADO VACÍO
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No hay PDFs en este proceso',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Los documentos aparecerán aquí cuando se registren',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // DIÁLOGO DE INFORMACIÓN
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: Color(0xFF1B5E6B)),
            const SizedBox(width: 8),
            const Text(
              'Información',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Proceso', proceso),
            const Divider(height: 12),
            _buildInfoRow('Total PDFs', '${pdfs.length}'),
            const Divider(height: 12),
            const Text(
              '💡 Toca una card para visualizar el PDF',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Color(0xFF1B5E6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E6B),
          ),
        ),
      ],
    );
  }
}
