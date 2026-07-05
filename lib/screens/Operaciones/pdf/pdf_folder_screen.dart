// screens/pdf_folder_screen.dart
import 'package:flutter/material.dart';
import 'package:i_miner/models/pdf_model.dart';
import 'package:i_miner/screens/Operaciones/pdf/pdf_detail_screen.dart';
import 'package:i_miner/config/data/database_helper.dart';

class PdfFolderScreen extends StatefulWidget {
  const PdfFolderScreen({super.key});

  @override
  State<PdfFolderScreen> createState() => _PdfFolderScreenState();
}

class _PdfFolderScreenState extends State<PdfFolderScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<PdfModel> _allPdfs = [];
  Map<String, List<PdfModel>> _groupedPdfs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfs();
  }

  Future<void> _loadPdfs() async {
    setState(() => _isLoading = true);

    try {
      final pdfsData = await _dbHelper.getAllPdfs();
      _allPdfs = pdfsData.map((data) => PdfModel.fromMap(data)).toList();
      _groupPdfsByProceso();
    } catch (e) {
      print('Error cargando PDFs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _groupPdfsByProceso() {
    _groupedPdfs = {};
    for (var pdf in _allPdfs) {
      if (!_groupedPdfs.containsKey(pdf.proceso)) {
        _groupedPdfs[pdf.proceso] = [];
      }
      _groupedPdfs[pdf.proceso]!.add(pdf);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📄 PDFs por Proceso'),
        backgroundColor: const Color(0xFF1B5E6B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPdfs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedPdfs.isEmpty
          ? _buildEmptyState()
          : _buildFolderList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay PDFs disponibles',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Los PDFs aparecerán aquí cuando se registren',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    final sortedKeys = _groupedPdfs.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final proceso = sortedKeys[index];
        final pdfs = _groupedPdfs[proceso]!;
        return _buildFolderCard(proceso, pdfs);
      },
    );
  }

  Widget _buildFolderCard(String proceso, List<PdfModel> pdfs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PdfDetailScreen(proceso: proceso, pdfs: pdfs),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E6B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder,
                  color: Color(0xFF1B5E6B),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proceso,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E6B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pdfs.length} ${pdfs.length == 1 ? 'PDF' : 'PDFs'}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E6B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pdfs.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
