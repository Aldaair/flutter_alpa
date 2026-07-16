import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/shared_catalog_repository.dart';
import 'package:i_miner/models/TipoPerforacion.dart';
import 'package:i_miner/models/DimLabor.dart';

class DialogoFormularioPerforacion extends StatefulWidget {
  final int operacionId;
  final int estadoId;
  final int procesoId;
  final Map<String, dynamic>? datosIniciales;
  final String estado;
  final String fecha;
  final String turno;
  final Color primaryColor;
  final Function(Map<String, dynamic>) onGuardar;

  const DialogoFormularioPerforacion({
    super.key,
    required this.operacionId,
    required this.estadoId,
    required this.procesoId,
    this.datosIniciales,
    required this.estado,
    required this.fecha,
    required this.turno,
    this.primaryColor = const Color(0xFF1B5E6B),
    required this.onGuardar,
  });

  @override
  State<DialogoFormularioPerforacion> createState() =>
      _DialogoFormularioPerforacionState();
}

class _HorizontalFrontOption {
  const _HorizontalFrontOption({
    required this.laborId,
    required this.alaId,
    required this.tipoLabor,
    required this.labor,
    required this.ala,
    required this.mina,
    required this.zona,
    required this.area,
    required this.fase,
    required this.estructuraMineral,
    required this.nivel,
  });

  final int? laborId;
  final int? alaId;
  final String tipoLabor;
  final String labor;
  final String ala;
  final String mina;
  final String zona;
  final String area;
  final String fase;
  final String estructuraMineral;
  final String nivel;
}

class _DialogoFormularioPerforacionState
    extends State<DialogoFormularioPerforacion> {
  bool isEditable = false;
  bool isLoading = true;

  final TextEditingController talProdController = TextEditingController();
  final TextEditingController talRimadosController = TextEditingController();
  final TextEditingController talAlivioController = TextEditingController();
  final TextEditingController talRepasoController = TextEditingController();
  final TextEditingController longitudBarraController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();

  String? minaSeleccionada;
  String? zonaSeleccionada;
  String? areaSeleccionada;
  String? faseSeleccionada;
  String? estructuraMineralSeleccionada;
  String? nivelSeleccionado;
  String? tipoLaborSeleccionado;
  String? laborSeleccionado;
  String? alaSeleccionado;
  String? tipoPerforacionSeleccionado;
  String? longitudBarraSeleccionada;

  int laborFieldResetKey = 0;
  int alaFieldResetKey = 0;

  List<String> opcionesTipoPerforacion = [];
  List<String> opcionesLongitudBarras = [];
  List<TipoPerforacion> tiposPerforacionCompletos = [];
  List<DimLabor> laboresCatalogo = [];

  _HorizontalFrontOption? selectedManualFront;
  String? selectedManualFrontLabel;

  final Map<String, _HorizontalFrontOption> _manualFrontMap = {};
  final SharedCatalogRepository _sharedCatalogRepository =
      SharedCatalogRepository();

  @override
  void initState() {
    super.initState();
    isEditable = widget.estado.toLowerCase() != 'cerrado';
    _cargarDatosIniciales();
    _cargarDatosDesdeBD();
  }

  Future<void> _cargarDatosDesdeBD() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([
        _cargarTiposPerforacion(),
        _cargarLongitudBarras(),
        _cargarLabores(),
      ]);

      _rebuildManualFrontMap();
    } catch (e) {
      print('Error cargando datos: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _cargarLabores() async {
    try {
      final data = await _sharedCatalogRepository.getLabores();
      if (!mounted) return;
      setState(() {
        laboresCatalogo = data;
      });
    } catch (e) {
      print('Error cargando labores: $e');
    }
  }

  Future<void> _cargarTiposPerforacion() async {
    try {
      final dbHelper = DatabaseHelper();
      tiposPerforacionCompletos = await dbHelper.getTiposPerforacionByProcesoId(
        widget.procesoId,
      );

      final lista =
          tiposPerforacionCompletos
              .map((t) => t.nombre)
              .where((n) => n.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (!mounted) return;
      setState(() {
        opcionesTipoPerforacion = lista;
      });
    } catch (e) {
      print('Error cargando tipos de perforación: $e');
      if (!mounted) return;
      setState(() {
        opcionesTipoPerforacion = [
          'Perforación 1',
          'Perforación 2',
          'Perforación 3',
          'Perforación 4',
        ];
      });
    }
  }

  Future<void> _cargarLongitudBarras() async {
    try {
      final dbHelper = DatabaseHelper();
      final data = await dbHelper.getLongitudBarrasPorProceso(
        'PERFORACIÓN HORIZONTAL',
      );

      final lista =
          data.map((e) => e['longitud_pies'].toString()).toSet().toList()
            ..sort((a, b) => double.parse(a).compareTo(double.parse(b)));

      if (!mounted) return;
      setState(() {
        opcionesLongitudBarras = lista;
      });
    } catch (e) {
      print('Error cargando longitudes: $e');
    }
  }

  void _cargarDatosIniciales() {
    if (widget.datosIniciales == null) return;

    setState(() {
      minaSeleccionada =
          widget.datosIniciales!['mina']?.toString().isNotEmpty == true
          ? widget.datosIniciales!['mina'].toString()
          : null;
      zonaSeleccionada =
          widget.datosIniciales!['zona']?.toString().isNotEmpty == true
          ? widget.datosIniciales!['zona'].toString()
          : null;
      areaSeleccionada =
          widget.datosIniciales!['area']?.toString().isNotEmpty == true
          ? widget.datosIniciales!['area'].toString()
          : null;
      faseSeleccionada =
          widget.datosIniciales!['fase']?.toString().isNotEmpty == true
          ? widget.datosIniciales!['fase'].toString()
          : null;
      estructuraMineralSeleccionada =
          widget.datosIniciales!['estructura_mineral']?.toString().isNotEmpty ==
              true
          ? widget.datosIniciales!['estructura_mineral'].toString()
          : null;
      tipoLaborSeleccionado =
          widget.datosIniciales!['tipo_labor']?.toString().isNotEmpty == true
          ? widget.datosIniciales!['tipo_labor'].toString()
          : null;
      laborSeleccionado =
          widget.datosIniciales!['labor']?.toString().isNotEmpty == true
          ? widget.datosIniciales!['labor'].toString()
          : null;
      alaSeleccionado =
          widget.datosIniciales!['ala']?.toString().isNotEmpty == true
          ? widget.datosIniciales!['ala'].toString()
          : null;
      nivelSeleccionado =
          widget.datosIniciales!['nivel']?.toString().isNotEmpty == true
          ? widget.datosIniciales!['nivel'].toString()
          : null;
      tipoPerforacionSeleccionado =
          widget.datosIniciales!['tipo_perforacion']?.toString().isNotEmpty ==
              true
          ? widget.datosIniciales!['tipo_perforacion'].toString()
          : null;

      talProdController.text =
          widget.datosIniciales!['tal_prod']?.toString() ?? '';
      talRimadosController.text =
          widget.datosIniciales!['tal_rimados']?.toString() ?? '';
      talAlivioController.text =
          widget.datosIniciales!['tal_alivio']?.toString() ?? '';
      talRepasoController.text =
          widget.datosIniciales!['tal_repaso']?.toString() ?? '';
      longitudBarraController.text =
          widget.datosIniciales!['long_barras']?.toString() ?? '';
      observacionesController.text =
          widget.datosIniciales!['observaciones']?.toString() ?? '';
    });
  }

  void _rebuildManualFrontMap() {
    _manualFrontMap.clear();

    void registerOption(_HorizontalFrontOption option) {
      if (option.tipoLabor.trim().isEmpty || option.labor.trim().isEmpty) {
        return;
      }
      final label = _buildManualFrontLabel(
        option.tipoLabor,
        option.labor,
        option.ala,
        option.nivel,
      );
      _manualFrontMap[label] = option;
    }

    for (final labor in laboresCatalogo) {
      registerOption(
        _HorizontalFrontOption(
          laborId: labor.laborId,
          alaId: labor.alaId,
          tipoLabor: labor.tipoLaborNombre,
          labor: labor.nombreLabor,
          ala: labor.alaNombre,
          mina: labor.minaNombre,
          zona: labor.zonaNombre,
          area: labor.areaNombre,
          fase: labor.faseNombre,
          estructuraMineral: labor.estructuraMineralNombre,
          nivel: labor.nivelNombre,
        ),
      );
    }

    final currentLabel =
        selectedManualFrontLabel ?? _buildManualFrontLabelFromState();
    if (currentLabel != null) {
      selectedManualFront = _manualFrontMap[currentLabel];
    }
  }

  String _buildManualFrontLabel(
    String tipoLabor,
    String labor, [
    String? ala,
    String? nivel,
  ]) {
    final base = '${tipoLabor.trim()} - ${labor.trim()}';
    final normalizedAla = ala?.trim() ?? '';
    final normalizedNivel = nivel?.trim() ?? '';
    final parts = <String>[base];
    if (normalizedAla.isNotEmpty) {
      parts.add(normalizedAla);
    }
    if (normalizedNivel.isNotEmpty) {
      parts.add('Nivel $normalizedNivel');
    }
    return parts.join(' - ');
  }

  String? _buildManualFrontLabelFromState() {
    final tipoLabor = tipoLaborSeleccionado?.trim();
    final labor = laborSeleccionado?.trim();
    if (tipoLabor == null || tipoLabor.isEmpty) return null;
    if (labor == null || labor.isEmpty) return null;
    return _buildManualFrontLabel(
      tipoLabor,
      labor,
      alaSeleccionado,
      nivelSeleccionado,
    );
  }

  _HorizontalFrontOption? _resolveManualFrontSelection() {
    final label = selectedManualFrontLabel ?? _buildManualFrontLabelFromState();
    if (label == null) return null;
    return _manualFrontMap[label];
  }

  Map<String, dynamic> _buildLaborPayload() {
    final manualFront = _resolveManualFrontSelection();

    return <String, dynamic>{
      'labor_id': manualFront?.laborId,
      'frente_origen': 'otro_frente',
      'tipo_labor': manualFront?.tipoLabor ?? '',
      'labor': manualFront?.labor ?? '',
      'ala': manualFront?.ala ?? '',
      'ala_id': manualFront?.alaId,
      'nivel': manualFront?.nivel ?? '',
    };
  }

  void _clearManualFrontSelection() {
    setState(() {
      selectedManualFront = null;
      selectedManualFrontLabel = null;
      minaSeleccionada = null;
      zonaSeleccionada = null;
      areaSeleccionada = null;
      faseSeleccionada = null;
      estructuraMineralSeleccionada = null;
      nivelSeleccionado = null;
      tipoLaborSeleccionado = null;
      laborSeleccionado = null;
      alaSeleccionado = null;
    });
  }

  void _aplicarManualFront(_HorizontalFrontOption option) {
    setState(() {
      tipoLaborSeleccionado = option.tipoLabor;
      laborSeleccionado = option.labor;
      alaSeleccionado = option.ala;
      minaSeleccionada = option.mina;
      zonaSeleccionada = option.zona;
      areaSeleccionada = option.area;
      faseSeleccionada = option.fase;
      estructuraMineralSeleccionada = option.estructuraMineral;
      nivelSeleccionado = option.nivel;
      selectedManualFront = option;
      selectedManualFrontLabel = _buildManualFrontLabel(
        option.tipoLabor,
        option.labor,
        option.ala,
        option.nivel,
      );
    });
  }

  String _normalizeSearchValue(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _buildLocationSummary() {
    return 'Ubicación: ${minaSeleccionada ?? '-'} / ${zonaSeleccionada ?? '-'} / ${areaSeleccionada ?? '-'} / ${faseSeleccionada ?? '-'}';
  }

  Future<void> _guardarDatos() async {
    if (tipoPerforacionSeleccionado == null) {
      _mostrarSnackbar(
        'Debe seleccionar un tipo de perforación',
        Colors.orange,
      );
      return;
    }

    final datosFormulario = <String, dynamic>{
      ..._buildLaborPayload(),
      'tal_prod': int.tryParse(talProdController.text) ?? 0,
      'tal_rimados': int.tryParse(talRimadosController.text) ?? 0,
      'tal_alivio': int.tryParse(talAlivioController.text) ?? 0,
      'tal_repaso': int.tryParse(talRepasoController.text) ?? 0,
      'long_barras': double.tryParse(longitudBarraController.text) ?? 0.0,
      'tipo_perforacion': tipoPerforacionSeleccionado ?? '',
      'tipo_perforacion_id': _obtenerIdTipoPerforacion(
        tipoPerforacionSeleccionado,
      ),
      'observaciones': observacionesController.text,
    };

    widget.onGuardar(datosFormulario);
    _mostrarSnackbar('Formulario guardado correctamente', Colors.green);
    Navigator.pop(context);
  }

  int? _obtenerIdTipoPerforacion(String? nombre) {
    if (nombre == null) return null;
    try {
      return tiposPerforacionCompletos
          .firstWhere((tipo) => tipo.nombre == nombre)
          .id;
    } catch (_) {
      return null;
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

  @override
  void dispose() {
    talProdController.dispose();
    talRimadosController.dispose();
    talAlivioController.dispose();
    talRepasoController.dispose();
    longitudBarraController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 950,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSeccionCompacta(
                            icon: Icons.location_on,
                            titulo: 'Ubicación',
                            children: [
                              Expanded(child: _buildSingleFrontSelector()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSeccionCompacta(
                            icon: Icons.golf_course,
                            titulo: 'Taladros',
                            children: [
                              _buildCompactTextField(
                                label: 'Producción',
                                controller: talProdController,
                                icon: Icons.calculate,
                              ),
                              const SizedBox(width: 8),
                              _buildCompactTextField(
                                label: 'Rimados',
                                controller: talRimadosController,
                                icon: Icons.calculate,
                              ),
                              const SizedBox(width: 8),
                              _buildCompactTextField(
                                label: 'Alivio',
                                controller: talAlivioController,
                                icon: Icons.calculate,
                              ),
                              const SizedBox(width: 8),
                              _buildCompactTextField(
                                label: 'Repaso',
                                controller: talRepasoController,
                                icon: Icons.calculate,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSeccionCompacta(
                            icon: Icons.height,
                            titulo: 'Barras',
                            children: [
                              _buildCompactTextField(
                                label: 'Longitud (pies)',
                                controller: longitudBarraController,
                                icon: Icons.straighten,
                                allowDecimal: true,
                              ),
                              const SizedBox(width: 8),
                              _buildCompactDropdownField(
                                label: 'Seleccione tipo',
                                value: tipoPerforacionSeleccionado,
                                items: opcionesTipoPerforacion,
                                onChanged: isEditable
                                    ? (value) => setState(
                                        () =>
                                            tipoPerforacionSeleccionado = value,
                                      )
                                    : null,
                                icon: Icons.settings_input_component,
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 1,
                                child: const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSeccionObservaciones(),
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
      ),
    );
  }

  Widget _buildSeccionObservaciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.note_alt, size: 14, color: widget.primaryColor),
            ),
            const SizedBox(width: 6),
            Text(
              'Observaciones',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: observacionesController,
            enabled: isEditable,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Ingrese observaciones...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(
                  Icons.comment,
                  size: 16,
                  color: widget.primaryColor.withValues(alpha: 0.7),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              alignLabelWithHint: true,
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionCompacta({
    required IconData icon,
    required String titulo,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 14, color: widget.primaryColor),
            ),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: children.map((child) {
            if (child is SizedBox && child.width == 8) {
              return child;
            }
            return Expanded(child: child);
          }).toList(),
        ),
      ],
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
            child: const Icon(Icons.description, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Formulario de Perforación',
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

  Widget _buildCompactTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.number,
    bool allowDecimal = false,
  }) {
    final formatter = allowDecimal
        ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
        : FilteringTextInputFormatter.digitsOnly;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        enabled: isEditable,
        keyboardType: allowDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : keyboardType,
        inputFormatters: [formatter],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          prefixIcon: Icon(icon, size: 14, color: widget.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildCompactDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
    required IconData icon,
  }) {
    final valueExists = value != null && items.contains(value);
    final isEnabled = onChanged != null && isEditable;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valueExists ? value : null,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: widget.primaryColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  items.isEmpty ? 'Cargando...' : label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: widget.primaryColor,
          ),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(6),
          items: items.isEmpty
              ? [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'No hay opciones',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ]
              : items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
          onChanged: isEnabled ? onChanged : null,
        ),
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
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
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
                children: [Text('Guardar')],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchableAutocompleteField({
    required String label,
    required String hintText,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSelected,
    bool enabled = true,
    int resetKey = 0,
  }) {
    final isFieldEnabled = isEditable && enabled;

    return RawAutocomplete<String>(
      key: ValueKey('$label-$resetKey'),
      initialValue: TextEditingValue(text: selectedValue ?? ''),
      optionsBuilder: (textEditingValue) {
        if (!isFieldEnabled) {
          return const Iterable<String>.empty();
        }
        final query = _normalizeSearchValue(textEditingValue.text);
        if (query.isEmpty) return options;
        return options.where(
          (option) => _normalizeSearchValue(option).contains(query),
        );
      },
      onSelected: isFieldEnabled ? onSelected : null,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: isFieldEnabled,
          onChanged: isFieldEnabled ? onChanged : null,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.search, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            isDense: true,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, autocompleteOptions) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 500,
              height: 240,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: autocompleteOptions.length,
                itemBuilder: (context, index) {
                  final option = autocompleteOptions.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleFrontSelector() {
    final selected = _resolveManualFrontSelection() ?? selectedManualFront;
    final selectedDetails = selected?.laborId != null ? selected : null;
    final options = _manualFrontMap.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchableAutocompleteField(
          label: 'Frente de Trabajo',
          hintText: 'Buscar por tipo labor, labor o ala...',
          options: options,
          selectedValue:
              selectedManualFrontLabel ?? _buildManualFrontLabelFromState(),
          onChanged: (value) {
            if (value !=
                (selectedManualFrontLabel ??
                    _buildManualFrontLabelFromState())) {
              _clearManualFrontSelection();
            }
          },
          onSelected: (value) {
            final option = _manualFrontMap[value];
            if (option != null) {
              _aplicarManualFront(option);
            }
          },
        ),
        if (selectedDetails != null) ...[
          const SizedBox(height: 8),
          Text(_buildLocationSummary(), style: const TextStyle(fontSize: 12)),
          Text(
            '${selectedDetails.estructuraMineral} / Nivel ${selectedDetails.nivel} / ${selectedDetails.tipoLabor} / ${selectedDetails.labor}${selectedDetails.ala.isNotEmpty ? ' / Ala ${selectedDetails.ala}' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}
