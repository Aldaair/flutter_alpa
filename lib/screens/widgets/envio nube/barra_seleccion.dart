import 'package:flutter/material.dart';

class BarraSeleccion extends StatelessWidget {
  final int cantidadSeleccionados;
  final VoidCallback onEliminar;
  final VoidCallback onExportar;
  final Color primaryColor;
  final bool isExportEnabled;

  const BarraSeleccion({
    super.key,
    required this.cantidadSeleccionados,
    required this.onEliminar,
    required this.onExportar,
    required this.primaryColor,
    this.isExportEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (cantidadSeleccionados == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              cantidadSeleccionados.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'seleccionado(s)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onPressed: isExportEnabled ? onExportar : null,
            tooltip: isExportEnabled
                ? 'Exportar seleccionados'
                : 'Envío en progreso',
            iconSize: 20,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: onEliminar,
            tooltip: 'Eliminar seleccionados',
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
