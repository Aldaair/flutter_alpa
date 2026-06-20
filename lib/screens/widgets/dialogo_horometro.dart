import 'package:flutter/material.dart';

class HorometroDef {
  final String key;
  final String nombre;

  const HorometroDef({required this.key, required this.nombre});

  factory HorometroDef.fromRawNombre(String rawNombre) {
    return HorometroDef(key: rawNombre, nombre: _toDisplayName(rawNombre));
  }

  static String _toDisplayName(String nombre) {
    const displayNames = {
      'diesel': 'Diesel',
      'electrico': 'Eléctrico',
      'percusion': 'Percusión',
      'horometro': 'Horómetro',
      'horometro_principal': 'Horómetro Principal',
      'empernador': 'Empernador',
    };
    return displayNames[nombre] ?? nombre
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class DialogoHorometro extends StatefulWidget {
  final int operacionId;
  final String estado;
  final Map<String, dynamic> horometrosData;
  final Color primaryColor;

  final List<HorometroDef> horometroDefs;
  final Future<bool> Function(
      int operacionId, Map<String, dynamic> horometrosToSave) onSave;
  final String? headerTitle;
  final String? headerSubtitle;
  final double col0Width;
  final bool enableResponsive;
  final bool showFinalEqualWarning;
  final bool useZeroForInop;
  final bool useNameInError;

  const DialogoHorometro({
    super.key,
    required this.operacionId,
    required this.estado,
    required this.horometrosData,
    required this.horometroDefs,
    required this.onSave,
    this.primaryColor = const Color(0xFF1B5E6B),
    this.headerTitle,
    this.headerSubtitle,
    this.col0Width = 150,
    this.enableResponsive = false,
    this.showFinalEqualWarning = true,
    this.useZeroForInop = false,
    this.useNameInError = false,
  });

  @override
  State<DialogoHorometro> createState() => _DialogoHorometroState();
}

class _DialogoHorometroState extends State<DialogoHorometro> {
  late List<Map<String, dynamic>> horometros;
  bool isLoading = true;
  bool isEditable = false;
  Map<int, String> erroresValidacion = {};
  bool isSmallScreen = false;

  late List<TextEditingController> inicialControllers;
  late List<TextEditingController> finalControllers;

  @override
  void initState() {
    super.initState();
    isEditable = widget.estado.toLowerCase() != 'cerrado';
    _cargarHorometros();
  }

  void _cargarHorometros() {
    setState(() {
      horometros = List.generate(widget.horometroDefs.length, (i) {
        final def = widget.horometroDefs[i];
        final raw = widget.horometrosData[def.key] ?? {};
        return {
          'id': i + 1,
          'nombre': def.nombre,
          'inicial': raw['inicio'] ?? 0,
          'final': raw['final'] ?? 0,
          'EstaOP': raw['op'] == true ? 1 : 0,
          'EstaINOP': raw['inop'] == true ? 1 : 0,
        };
      });

      _inicializarControladores();
      isLoading = false;
      _validarTodos();
    });
  }

  void _inicializarControladores() {
    inicialControllers = List.generate(horometros.length, (index) {
      return TextEditingController(
        text: horometros[index]['inicial']?.toString() ?? '',
      );
    });

    finalControllers = List.generate(horometros.length, (index) {
      return TextEditingController(
        text: horometros[index]['final']?.toString() ?? '',
      );
    });
  }

  @override
  void dispose() {
    for (var c in inicialControllers) {
      c.dispose();
    }
    for (var c in finalControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  String? _validarHorometro(Map<String, dynamic> horometro, int index) {
    final inicial = horometro['inicial'] ?? 0;
    final finalHoro = horometro['final'] ?? 0;
    final estaOP = horometro['EstaOP'] == 1;
    final estaINOP = horometro['EstaINOP'] == 1;

    if (estaINOP) {
      if (widget.useZeroForInop) {
        if (inicial != 0 && inicial != null) {
          return 'INOP: El valor inicial debe ser 0';
        }
        if (finalHoro != 0 && finalHoro != null) {
          return 'INOP: El valor final debe ser 0';
        }
      } else {
        if (inicial != 0) {
          return 'INOP: El valor inicial debe estar vacío o 0';
        }
        if (finalHoro != 0) {
          return 'INOP: El valor final debe estar vacío o 0';
        }
      }
    }

    if (estaOP) {
      if (inicial == null) {
        return 'OP: Debe tener valor inicial';
      }
    }

    if (estaOP && estaINOP) {
      return 'No puede seleccionar OP e INOP';
    }

    if (!estaOP && !estaINOP) {
      return 'Seleccione OP o INOP';
    }

    return null;
  }

  void _validarTodos() {
    erroresValidacion.clear();
    for (int i = 0; i < horometros.length; i++) {
      final error = _validarHorometro(horometros[i], i);
      if (error != null) {
        erroresValidacion[i] = error;
      }
    }
    setState(() {});
  }

  bool _hayErrores() => erroresValidacion.isNotEmpty;

  Future<void> _guardarHorometros() async {
    _validarTodos();

    if (_hayErrores()) {
      String mensajeError;
      if (widget.useNameInError) {
        mensajeError = 'Errores en: ';
        erroresValidacion.forEach((index, error) {
          mensajeError += '${horometros[index]['nombre']}, ';
        });
      } else {
        mensajeError = 'Errores en filas: ';
        erroresValidacion.forEach((index, error) {
          mensajeError += '${index + 1}, ';
        });
      }
      mensajeError = mensajeError.substring(0, mensajeError.length - 2);

      _mostrarSnackbar(mensajeError, Colors.red);
      return;
    }

    Map<String, dynamic> horometrosToSave = {};
    for (int i = 0; i < widget.horometroDefs.length; i++) {
      horometrosToSave[widget.horometroDefs[i].key] = {
        'inicio': horometros[i]['inicial'] ?? 0,
        'final': horometros[i]['final'] ?? 0,
        'op': horometros[i]['EstaOP'] == 1,
        'inop': horometros[i]['EstaINOP'] == 1,
      };
    }

    final guardado =
        await widget.onSave(widget.operacionId, horometrosToSave);

    if (guardado && mounted) {
      _mostrarSnackbar('Horómetros guardados correctamente', Colors.green);
      Navigator.pop(context, true);
    } else if (mounted) {
      _mostrarSnackbar('Error al guardar los horómetros', Colors.red);
    }
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _handleOPChange(int index, bool value) {
    setState(() {
      horometros[index]['EstaOP'] = value ? 1 : 0;
      if (value) {
        horometros[index]['EstaINOP'] = 0;
      }
    });
    _validarTodos();
  }

  void _handleINOPChange(int index, bool value) {
    setState(() {
      horometros[index]['EstaINOP'] = value ? 1 : 0;
      if (value) {
        horometros[index]['EstaOP'] = 0;
        if (widget.useZeroForInop) {
          horometros[index]['inicial'] = 0;
          horometros[index]['final'] = 0;
          inicialControllers[index].text = '0';
          finalControllers[index].text = '0';
        } else {
          horometros[index]['inicial'] = null;
          horometros[index]['final'] = null;
          inicialControllers[index].text = '';
          finalControllers[index].text = '';
        }
      }
    });
    _validarTodos();
  }

  void _handleInicialChange(int index, String value) {
    horometros[index]['inicial'] = _parseDouble(value);
    _validarTodos();
  }

  void _handleFinalChange(int index, String value) {
    horometros[index]['final'] = _parseDouble(value);
    _validarTodos();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enableResponsive) {
      isSmallScreen = MediaQuery.of(context).size.width < 600;
    }

    final dialogWidth = isSmallScreen
        ? MediaQuery.of(context).size.width * 0.95
        : MediaQuery.of(context).size.width * 0.75;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (widget.horometroDefs.isEmpty)
              Container(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay horómetros asociados a este equipo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: isSmallScreen
                      ? _buildCardsView()
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildTable(),
                        ),
                ),
              ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: widget.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.speed,
              color: Colors.white,
              size: isSmallScreen ? 16 : 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.headerTitle ?? 'Horómetros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.headerSubtitle != null)
                  Text(
                    widget.headerSubtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                if (_hayErrores())
                  Text(
                    '⚠️ ${erroresValidacion.length} error(es)',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: isSmallScreen ? 9 : 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isEditable ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isEditable ? 'EDITABLE' : 'SOLO LECTURA',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 8 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: 8,
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 12 : 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isEditable)
            ElevatedButton(
              onPressed: _guardarHorometros,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _hayErrores() ? Colors.grey : widget.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _hayErrores() ? Icons.error_outline : Icons.save,
                    size: isSmallScreen ? 12 : 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hayErrores()
                        ? (isSmallScreen ? 'Corregir' : 'Corregir errores')
                        : 'Guardar',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200),
          verticalInside: BorderSide(color: Colors.grey.shade200),
        ),
        columnWidths: {
          0: FixedColumnWidth(widget.col0Width),
          1: FixedColumnWidth(90),
          2: FixedColumnWidth(90),
          3: FixedColumnWidth(50),
          4: FixedColumnWidth(50),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: [
              _buildHeaderCell('Nombre'),
              _buildHeaderCell('Inicial'),
              _buildHeaderCell('Final'),
              _buildHeaderCell('OP'),
              _buildHeaderCell('INOP'),
            ],
          ),
          for (int i = 0; i < horometros.length; i++)
            TableRow(
              decoration: BoxDecoration(
                color: erroresValidacion.containsKey(i)
                    ? Colors.red.withOpacity(0.05)
                    : null,
              ),
              children: [
                _buildCell(horometros[i]['nombre'], isBold: true),
                _buildEditableCell(
                  index: i,
                  controller: inicialControllers[i],
                  isEditable: isEditable && horometros[i]['EstaOP'] == 1,
                  onChanged: (value) => _handleInicialChange(i, value),
                  error: erroresValidacion.containsKey(i)
                      ? erroresValidacion[i]
                      : null,
                ),
                _buildEditableCell(
                  index: i,
                  controller: finalControllers[i],
                  isEditable: isEditable && horometros[i]['EstaOP'] == 1,
                  onChanged: (value) => _handleFinalChange(i, value),
                  error: erroresValidacion.containsKey(i)
                      ? erroresValidacion[i]
                      : null,
                ),
                _buildCheckboxCell(
                  value: horometros[i]['EstaOP'] == 1,
                  isEditable: isEditable,
                  onChanged: (value) => _handleOPChange(i, value),
                ),
                _buildCheckboxCell(
                  value: horometros[i]['EstaINOP'] == 1,
                  isEditable: isEditable,
                  onChanged: (value) => _handleINOPChange(i, value),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildCell(String text, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w500 : FontWeight.normal,
          color: Colors.grey.shade900,
        ),
      ),
    );
  }

  Widget _buildEditableCell({
    required int index,
    required TextEditingController controller,
    required bool isEditable,
    required Function(String) onChanged,
    String? error,
  }) {
    bool isFinalEqual = false;
    if (widget.showFinalEqualWarning &&
        !isEditable &&
        horometros[index]['EstaOP'] == 1) {
      final inicial = horometros[index]['inicial'];
      final finalHoro = horometros[index]['final'];
      if (inicial != null && finalHoro != null && finalHoro == inicial) {
        isFinalEqual = true;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            enabled: isEditable,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 12,
              color: isFinalEqual ? Colors.orange.shade700 : null,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: error != null
                      ? Colors.red
                      : (isFinalEqual
                          ? Colors.orange.shade300
                          : Colors.grey.shade300),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: error != null
                      ? Colors.red
                      : (isFinalEqual
                          ? Colors.orange.shade300
                          : Colors.grey.shade300),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: error != null
                      ? Colors.red
                      : (isFinalEqual
                          ? Colors.orange
                          : widget.primaryColor),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              filled: !isEditable,
              fillColor: error != null
                  ? Colors.red.withOpacity(0.05)
                  : (isFinalEqual
                      ? Colors.orange.withOpacity(0.05)
                      : (isEditable ? Colors.white : Colors.grey.shade50)),
              hintText: !isEditable ? 'INOP - Bloqueado' : null,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (isFinalEqual)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Text(
                '⚠️ Final igual a inicial',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckboxCell({
    required bool value,
    required bool isEditable,
    required Function(bool) onChanged,
  }) {
    return Center(
      child: Transform.scale(
        scale: 0.8,
        child: Checkbox(
          value: value,
          onChanged: isEditable
              ? (bool? newValue) {
                  if (newValue != null) onChanged(newValue);
                }
              : null,
          activeColor: widget.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildCardsView() {
    return Column(
      children: List.generate(horometros.length, (index) {
        final horometro = horometros[index];
        final hasError = erroresValidacion.containsKey(index);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey.shade300,
              width: hasError ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.speed,
                        size: 20, color: widget.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        horometro['nombre'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                    if (hasError)
                      const Icon(Icons.error_outline,
                          size: 20, color: Colors.red),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildCardField(
                      label: 'Horómetro Inicial',
                      controller: inicialControllers[index],
                      isEditable:
                          isEditable && horometro['EstaOP'] == 1,
                      onChanged: (v) =>
                          _handleInicialChange(index, v),
                      error: hasError ? erroresValidacion[index] : null,
                    ),
                    const SizedBox(height: 12),
                    _buildCardField(
                      label: 'Horómetro Final',
                      controller: finalControllers[index],
                      isEditable:
                          isEditable && horometro['EstaOP'] == 1,
                      onChanged: (v) => _handleFinalChange(index, v),
                      error: null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildCardCheckbox(
                          label: 'OP',
                          value: horometro['EstaOP'] == 1,
                          onChanged: (v) =>
                              _handleOPChange(index, v),
                          isEditable: isEditable,
                        ),
                        const SizedBox(width: 20),
                        _buildCardCheckbox(
                          label: 'INOP',
                          value: horometro['EstaINOP'] == 1,
                          onChanged: (v) =>
                              _handleINOPChange(index, v),
                          isEditable: isEditable,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCardField({
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    required Function(String) onChanged,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: isEditable,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: 14,
            color: error != null ? Colors.red : null,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error != null ? Colors.red : widget.primaryColor,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            filled: !isEditable,
            fillColor: !isEditable ? Colors.grey.shade50 : null,
            hintText: !isEditable ? 'Bloqueado' : null,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            errorText: error,
            errorStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildCardCheckbox({
    required String label,
    required bool value,
    required bool isEditable,
    required Function(bool) onChanged,
  }) {
    return Expanded(
      child: InkWell(
        onTap: isEditable ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: value
                ? widget.primaryColor.withOpacity(0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value ? widget.primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: value
                    ? widget.primaryColor
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: value
                      ? widget.primaryColor
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
