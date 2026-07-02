import 'package:flutter/material.dart';

class DialogoCheckImagen extends StatefulWidget {
  final int operacionId;
  final Map<String, dynamic> controlLlantasData;
  final String estado;
  final Color primaryColor;
  final Future<bool> Function(int operacionId, Map<String, dynamic> datos)?
  onSave;

  const DialogoCheckImagen({
    super.key,
    required this.operacionId,
    required this.estado,
    required this.controlLlantasData,
    this.primaryColor = const Color(0xFF1B5E6B),
    this.onSave,
  });

  @override
  State<DialogoCheckImagen> createState() => _DialogoCheckImagenState();
}

class _DialogoCheckImagenState extends State<DialogoCheckImagen> {
  bool isEditable = false;

  bool value1 = true;
  bool value2 = true;
  bool value3 = true;
  bool value4 = true;

  @override
  void initState() {
    super.initState();
    isEditable = widget.estado.toLowerCase() != "cerrado";
    _cargarDatos();
  }

  void _cargarDatos() {
    value1 = widget.controlLlantasData['numero1'] ?? true;
    value2 = widget.controlLlantasData['numero2'] ?? true;
    value3 = widget.controlLlantasData['numero3'] ?? true;
    value4 = widget.controlLlantasData['numero4'] ?? true;
  }

  Future<void> _guardarDatos() async {
    Map<String, dynamic> controlLlantas = {
      'numero1': value1,
      'numero2': value2,
      'numero3': value3,
      'numero4': value4,
    };

    bool guardado;
    if (widget.onSave != null) {
      guardado = await widget.onSave!(widget.operacionId, controlLlantas);
    } else {
      guardado = false;
    }

    if (guardado) {
      _mostrarSnackbar('Inspección guardada correctamente', Colors.green);
      Navigator.pop(context);
    } else {
      _mostrarSnackbar('Error al guardar', Colors.red);
    }
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.92,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 860,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildLlantaLayout(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLlantaLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final compact = availableWidth < 520;
        final cardWidth =
            (compact ? availableWidth * 0.34 : availableWidth * 0.22)
                .clamp(110.0, 150.0)
                .toDouble();
        final cardHeight = 138.0;
        final imageHorizontalPadding = compact ? 12.0 : cardWidth * 0.48;
        final imageScale = compact ? 0.88 : 0.8;
        final imageWidth =
            ((availableWidth - (imageHorizontalPadding * 2)) * imageScale)
                .clamp(180.0, availableWidth)
            .toDouble();
        final imageHeight = imageWidth / (1083 / 555);
        final imageTop = cardHeight * 0.58;
        final layoutHeight = imageHeight + (imageTop * 2);
        final imageLeft = (availableWidth - imageWidth) / 2;
        final leftCardX = (imageLeft - (cardWidth * 0.18))
            .clamp(0.0, availableWidth - cardWidth)
            .toDouble();
        final rightCardX =
            (imageLeft + imageWidth - cardWidth + (cardWidth * 0.18))
                .clamp(0.0, availableWidth - cardWidth)
                .toDouble();

        return SizedBox(
          height: layoutHeight,
          child: Stack(
            children: [
              Positioned(
                left: imageLeft,
                top: imageTop,
                width: imageWidth,
                height: imageHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/img_llantas.PNG',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                left: leftCardX,
                top: 0,
                width: cardWidth,
                child: _buildCornerItem(
                  'NEUMÁTICO 1',
                  value1,
                  (v) => setState(() => value1 = v),
                ),
              ),
              Positioned(
                left: rightCardX,
                top: 0,
                width: cardWidth,
                child: _buildCornerItem(
                  'NEUMÁTICO 2',
                  value2,
                  (v) => setState(() => value2 = v),
                ),
              ),
              Positioned(
                left: leftCardX,
                top: layoutHeight - cardHeight,
                width: cardWidth,
                child: _buildCornerItem(
                  'NEUMÁTICO 3',
                  value3,
                  (v) => setState(() => value3 = v),
                ),
              ),
              Positioned(
                left: rightCardX,
                top: layoutHeight - cardHeight,
                width: cardWidth,
                child: _buildCornerItem(
                  'NEUMÁTICO 4',
                  value4,
                  (v) => setState(() => value4 = v),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCornerItem(
    String titulo,
    bool valor,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      height: 138,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _buildToggle(
            label: 'BUENO',
            icon: Icons.check_circle,
            selected: valor == true,
            color: Colors.green,
            onTap: isEditable ? () => onChanged(true) : null,
          ),
          const SizedBox(height: 8),
          _buildToggle(
            label: 'MALO',
            icon: Icons.cancel,
            selected: valor == false,
            color: Colors.red,
            onTap: isEditable ? () => onChanged(false) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: widget.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.tire_repair, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Inspección de neumáticos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildEstadoBadge(),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isEditable
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditable ? Colors.green : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isEditable ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isEditable ? 'EDITABLE' : 'LECTURA',
            style: TextStyle(
              color: isEditable ? Colors.green : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          const SizedBox(width: 8),
          if (isEditable)
            ElevatedButton(
              onPressed: _guardarDatos,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save, size: 14),
                  SizedBox(width: 6),
                  Text('Guardar'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
