import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/shared_catalog_repository.dart';
import 'package:i_miner/models/TipoPerforacion.dart';
import 'package:i_miner/models/DimMina.dart';
import 'package:i_miner/models/DimZona.dart';
import 'package:i_miner/models/DimArea.dart';
import 'package:i_miner/models/DimFase.dart';
import 'package:i_miner/models/DimTipoLabor.dart';
import 'package:i_miner/models/DimEstructuraMineral.dart';
import 'package:i_miner/models/DimNivel.dart';
import 'package:i_miner/models/DimAla.dart';
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

class _ManualFrontOption {
  const _ManualFrontOption({
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
  static const String _sinLaborLabel = 'SIN LABOR';

  bool isEditable = false;
  bool isLoading = true;

  // Controladores para cada taladro
  final TextEditingController nTaladrosProduccionController =
      TextEditingController();
  final TextEditingController metrosPerforadosProduccionController =
      TextEditingController();

  final TextEditingController nTaladrosRimadosController =
      TextEditingController();
  final TextEditingController metrosPerforadosRimadosController =
      TextEditingController();

  final TextEditingController nTaladrosAlivioController =
      TextEditingController();
  final TextEditingController metrosPerforadosAlivioController =
      TextEditingController();

  final TextEditingController nTaladrosRepasoController =
      TextEditingController();
  final TextEditingController metrosPerforadosRepasoController =
      TextEditingController();

  final TextEditingController observacionesController = TextEditingController();

  // Variables para los campos seleccionables (NUEVO ORDEN)
  String? minaSeleccionada;
  String? zonaSeleccionada;
  String? areaSeleccionada;
  String? faseSeleccionada;
  String? estructuraMineralSeleccionada;
  String? nivelSeleccionado;
  String? tipoLaborSeleccionado; // 1º
  String? laborSeleccionado; // 2º
  String? alaSeleccionado; // 3º

  String? tipoPerforacionSeleccionado;
  int laborFieldResetKey = 0;
  int alaFieldResetKey = 0;

  // Opciones para los dropdowns
  List<String> opcionesTipoPerforacion = [];
  // Catálogos desde shared DB
  List<DimMina> minasCatalogo = [];
  List<DimZona> zonasCatalogo = [];
  List<DimArea> areasCatalogo = [];
  List<DimFase> fasesCatalogo = [];
  List<DimTipoLabor> tiposLaborCatalogo = [];
  List<DimEstructuraMineral> estructurasMineralesCatalogo = [];
  List<DimNivel> nivelesCatalogo = [];
  List<DimAla> alasCatalogo = [];
  List<DimLabor> laboresCatalogo = [];

  // Almacenar objetos completos
  List<TipoPerforacion> tiposPerforacionCompletos = [];
  _ManualFrontOption? selectedManualFront;
  String? selectedManualFrontLabel;

  // Maps para RawAutocomplete
  final Map<String, _ManualFrontOption> _manualFrontMap = {};
  final SharedCatalogRepository _sharedCatalogRepository =
      SharedCatalogRepository();

  @override
  void initState() {
    super.initState();
    isEditable = widget.estado.toLowerCase() != "cerrado";
    _cargarDatosIniciales();
    _cargarDatosDesdeBD();
  }

  Future<void> _cargarDatosDesdeBD() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([_cargarTiposPerforacion(), _cargarCatalogos()]);

      _rebuildManualFrontMap();
    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cargarCatalogos() async {
    try {
      final results = await Future.wait([
        _sharedCatalogRepository.getMinas(),
        _sharedCatalogRepository.getZonas(),
        _sharedCatalogRepository.getAreas(),
        _sharedCatalogRepository.getFases(),
        _sharedCatalogRepository.getTiposLabor(),
        _sharedCatalogRepository.getEstructurasMinerales(),
        _sharedCatalogRepository.getNiveles(),
        _sharedCatalogRepository.getAlas(),
        _sharedCatalogRepository.getLabores(),
      ]);

      setState(() {
        minasCatalogo = results[0] as List<DimMina>;
        zonasCatalogo = results[1] as List<DimZona>;
        areasCatalogo = results[2] as List<DimArea>;
        fasesCatalogo = results[3] as List<DimFase>;
        tiposLaborCatalogo = results[4] as List<DimTipoLabor>;
        estructurasMineralesCatalogo = results[5] as List<DimEstructuraMineral>;
        nivelesCatalogo = results[6] as List<DimNivel>;
        alasCatalogo = results[7] as List<DimAla>;
        laboresCatalogo = results[8] as List<DimLabor>;
      });
    } catch (e) {
      print('Error cargando catálogos: $e');
    }
  }

  void _rebuildManualFrontMap() {
    _manualFrontMap.clear();
    _manualFrontMap[_sinLaborLabel] = const _ManualFrontOption(
      laborId: null,
      alaId: null,
      tipoLabor: '',
      labor: '',
      ala: '',
      mina: '',
      zona: '',
      area: '',
      fase: '',
      estructuraMineral: '',
      nivel: '',
    );

    void registerOption(DimLabor labor) {
      final laborId = labor.laborId;
      final alaId = labor.alaId;
      final tipoLabor = labor.tipoLaborNombre;
      final laborNombre = labor.nombreLabor;
      final ala = labor.alaNombre.trim();
      if (tipoLabor.trim().isEmpty || laborNombre.trim().isEmpty) {
        return;
      }
      final label = _buildManualFrontLabel(
        tipoLabor: tipoLabor,
        labor: laborNombre,
        ala: ala,
      );
      _manualFrontMap[label] = _ManualFrontOption(
        laborId: laborId,
        alaId: alaId,
        tipoLabor: tipoLabor.trim(),
        labor: laborNombre.trim(),
        ala: ala,
        mina: labor.minaNombre.trim(),
        zona: labor.zonaNombre.trim(),
        area: labor.areaNombre.trim(),
        fase: labor.faseNombre.trim(),
        estructuraMineral: labor.estructuraMineralNombre.trim(),
        nivel: labor.nivelNombre.trim(),
      );
    }

    for (final labor in laboresCatalogo) {
      registerOption(labor);
    }

    final currentLabel =
        selectedManualFrontLabel ?? _buildManualFrontLabelFromState();
    if (currentLabel != null) {
      selectedManualFront = _manualFrontMap[currentLabel];
    }
  }

  String _buildManualFrontLabel({
    required String tipoLabor,
    required String labor,
    String? ala,
  }) {
    final base = '${tipoLabor.trim()} - ${labor.trim()}';
    final alaNormalizada = ala?.trim() ?? '';
    if (alaNormalizada.isEmpty) {
      return base;
    }
    return '$base - $alaNormalizada';
  }

  String? _buildManualFrontLabelFromState() {
    final tipoLabor = tipoLaborSeleccionado?.trim();
    final labor = laborSeleccionado?.trim();
    if (tipoLabor == null || tipoLabor.isEmpty) return null;
    if (labor == null || labor.isEmpty) return null;
    return _buildManualFrontLabel(
      tipoLabor: tipoLabor,
      labor: labor,
      ala: alaSeleccionado,
    );
  }

  _ManualFrontOption? _resolveManualFrontSelection() {
    final label = selectedManualFrontLabel ?? _buildManualFrontLabelFromState();
    if (label == null) {
      return null;
    }

    return _manualFrontMap[label];
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

  void _aplicarManualFront(_ManualFrontOption option) {
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
      selectedManualFrontLabel = option.laborId == null
          ? _sinLaborLabel
          : _buildManualFrontLabel(
              tipoLabor: option.tipoLabor,
              labor: option.labor,
              ala: option.ala,
            );
    });
  }

  String _buildManualLocationSummary() {
    return 'Ubicación: ${minaSeleccionada ?? '-'} / ${zonaSeleccionada ?? '-'} / ${areaSeleccionada ?? '-'} / ${faseSeleccionada ?? '-'}';
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
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return options;
        return options.where((option) => option.toLowerCase().contains(query));
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

  Future<void> _cargarTiposPerforacion() async {
    try {
      final dbHelper = DatabaseHelper();

      print(
        '🔍 _cargarTiposPerforacion → Cargando tipos de perforación para procesoId=${widget.procesoId}',
      );
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
      print('🔍 _cargarTiposPerforacion → ${lista.length} tipos cargados');
      setState(() {
        opcionesTipoPerforacion = lista;
      });
    } catch (e) {
      print("Error cargando tipos perforación: $e");
    }
  }

  void _cargarDatosIniciales() {
    if (widget.datosIniciales != null) {
      setState(() {
        // Cargar en el nuevo orden
        minaSeleccionada = widget.datosIniciales!['mina']?.isNotEmpty == true
            ? widget.datosIniciales!['mina']
            : null;
        zonaSeleccionada = widget.datosIniciales!['zona']?.isNotEmpty == true
            ? widget.datosIniciales!['zona']
            : null;
        areaSeleccionada = widget.datosIniciales!['area']?.isNotEmpty == true
            ? widget.datosIniciales!['area']
            : null;
        faseSeleccionada = widget.datosIniciales!['fase']?.isNotEmpty == true
            ? widget.datosIniciales!['fase']
            : null;
        estructuraMineralSeleccionada =
            widget.datosIniciales!['estructura_mineral']?.isNotEmpty == true
            ? widget.datosIniciales!['estructura_mineral']
            : null;
        tipoLaborSeleccionado =
            widget.datosIniciales!['tipo_labor']?.isNotEmpty == true
            ? widget.datosIniciales!['tipo_labor']
            : null;
        laborSeleccionado = widget.datosIniciales!['labor']?.isNotEmpty == true
            ? widget.datosIniciales!['labor']
            : null;
        alaSeleccionado = widget.datosIniciales!['ala']?.isNotEmpty == true
            ? widget.datosIniciales!['ala']
            : null;
        nivelSeleccionado = widget.datosIniciales!['nivel']?.isNotEmpty == true
            ? widget.datosIniciales!['nivel']
            : null;

        if (widget.datosIniciales!.containsKey('labor_id') &&
            widget.datosIniciales!['labor_id'] == null &&
            (widget.datosIniciales!['labor']?.toString().isEmpty ?? true)) {
          selectedManualFrontLabel = _sinLaborLabel;
        }

        tipoPerforacionSeleccionado =
            widget.datosIniciales!['tipo_perforacion']?.isNotEmpty == true
            ? widget.datosIniciales!['tipo_perforacion']
            : null;

        // Cargar nuevos campos — .toString() porque se guardan como int/double
        nTaladrosProduccionController.text =
            widget.datosIniciales!['n_taladros_produccion']?.toString() ?? '';
        metrosPerforadosProduccionController.text =
            widget.datosIniciales!['metros_perforados_produccion']
                ?.toString() ??
            '';
        nTaladrosRimadosController.text =
            widget.datosIniciales!['n_taladros_rimados']?.toString() ?? '';
        metrosPerforadosRimadosController.text =
            widget.datosIniciales!['metros_perforados_rimados']?.toString() ??
            '';
        nTaladrosAlivioController.text =
            widget.datosIniciales!['n_taladros_alivio']?.toString() ?? '';
        metrosPerforadosAlivioController.text =
            widget.datosIniciales!['metros_perforados_alivio']?.toString() ??
            '';
        nTaladrosRepasoController.text =
            widget.datosIniciales!['n_taladros_repaso']?.toString() ?? '';
        metrosPerforadosRepasoController.text =
            widget.datosIniciales!['metros_perforados_repaso']?.toString() ??
            '';

        observacionesController.text =
            widget.datosIniciales!['observaciones'] ?? '';
      });
    }
  }

  Future<void> _guardarDatos() async {
    if (tipoPerforacionSeleccionado == null) {
      _mostrarSnackbar(
        'Debe seleccionar un tipo de perforación',
        Colors.orange,
      );
      return;
    }

    final manualFront = _resolveManualFrontSelection();
    if (manualFront == null) {
      _mostrarSnackbar(
        'Debe seleccionar un frente de trabajo válido',
        Colors.orange,
      );
      return;
    }

    Map<String, dynamic> datosFormulario = {
      'frente_origen': 'otro_frente',
      'labor_id': manualFront.laborId,
      'mina': manualFront.mina,
      'zona': manualFront.zona,
      'area': manualFront.area,
      'fase': manualFront.fase,
      'estructura_mineral': manualFront.estructuraMineral,
      'tipo_labor': manualFront.tipoLabor,
      'labor': manualFront.labor,
      'ala': manualFront.ala,
      'ala_id': manualFront.alaId,
      'nivel': manualFront.nivel,
      'n_taladros_produccion':
          int.tryParse(nTaladrosProduccionController.text) ?? 0,
      'metros_perforados_produccion':
          double.tryParse(metrosPerforadosProduccionController.text) ?? 0.0,
      'n_taladros_rimados': int.tryParse(nTaladrosRimadosController.text) ?? 0,
      'metros_perforados_rimados':
          double.tryParse(metrosPerforadosRimadosController.text) ?? 0.0,
      'n_taladros_alivio': int.tryParse(nTaladrosAlivioController.text) ?? 0,
      'metros_perforados_alivio':
          double.tryParse(metrosPerforadosAlivioController.text) ?? 0.0,
      'n_taladros_repaso': int.tryParse(nTaladrosRepasoController.text) ?? 0,
      'metros_perforados_repaso':
          double.tryParse(metrosPerforadosRepasoController.text) ?? 0.0,
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
    } catch (e) {
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
    nTaladrosProduccionController.dispose();
    metrosPerforadosProduccionController.dispose();
    nTaladrosRimadosController.dispose();
    metrosPerforadosRimadosController.dispose();
    nTaladrosAlivioController.dispose();
    metrosPerforadosAlivioController.dispose();
    nTaladrosRepasoController.dispose();
    metrosPerforadosRepasoController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1100,
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
                          // SECCIÓN 1: Ubicación
                          _buildSeccionCompacta(
                            icon: Icons.location_on,
                            titulo: 'Ubicación',
                            children: [_buildSingleFrontSelector()],
                          ),

                          const SizedBox(height: 12),

                          // Taladro Producción
                          _buildSeccionTaladro(
                            titulo: 'Taladro Producción',
                            icon: Icons.golf_course,
                            nTaladrosController: nTaladrosProduccionController,
                            metrosController:
                                metrosPerforadosProduccionController,
                            color: Colors.blue.shade700,
                          ),

                          const SizedBox(height: 12),

                          // Taladro Rimados
                          _buildSeccionTaladro(
                            titulo: 'Taladro Rimados',
                            icon: Icons.rotate_right,
                            nTaladrosController: nTaladrosRimadosController,
                            metrosController: metrosPerforadosRimadosController,
                            color: Colors.orange.shade700,
                          ),

                          const SizedBox(height: 12),

                          // Taladro Alivio
                          _buildSeccionTaladro(
                            titulo: 'Taladro Alivio',
                            icon: Icons.emergency,
                            nTaladrosController: nTaladrosAlivioController,
                            metrosController: metrosPerforadosAlivioController,
                            color: Colors.red.shade700,
                          ),

                          const SizedBox(height: 12),

                          // Taladro Repaso
                          _buildSeccionTaladro(
                            titulo: 'Taladro Repaso',
                            icon: Icons.refresh,
                            nTaladrosController: nTaladrosRepasoController,
                            metrosController: metrosPerforadosRepasoController,
                            color: Colors.purple.shade700,
                          ),

                          const SizedBox(height: 12),

                          // Tipo de Perforación
                          _buildSeccionCompacta(
                            icon: Icons.settings_input_component,
                            titulo: 'Tipo Perforación',
                            children: [
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
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Observaciones
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

  // ✅ NUEVO WIDGET: Sección para cada taladro con sus dos campos
  Widget _buildSeccionTaladro({
    required String titulo,
    required IconData icon,
    required TextEditingController nTaladrosController,
    required TextEditingController metrosController,
    required Color color,
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                label: 'Nro. Taladros',
                controller: nTaladrosController,
                icon: Icons.format_list_numbered,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactTextField(
                label: 'Metros perforados',
                controller: metrosController,
                icon: Icons.straighten,
                allowDecimal: true,
              ),
            ),
          ],
        ),
      ],
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
    bool valueExists = value != null && items.contains(value);
    bool isEnabled = onChanged != null && isEditable;

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
              : items.map((String item) {
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
              style: TextStyle(color: Colors.grey.shade700),
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

  Widget _buildSingleFrontSelector() {
    final selected = _resolveManualFrontSelection() ?? selectedManualFront;
    final selectedDetails = selected?.laborId != null ? selected : null;
    final isSinLaborSelected = selectedManualFrontLabel == _sinLaborLabel;
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
          Text(
            _buildManualLocationSummary(),
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '${selectedDetails.estructuraMineral} / Nivel ${selectedDetails.nivel} / ${selectedDetails.tipoLabor} / ${selectedDetails.labor}${selectedDetails.ala.isNotEmpty ? ' / Ala ${selectedDetails.ala}' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ] else if (isSinLaborSelected) ...[
          const SizedBox(height: 8),
          const Text(
            _sinLaborLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}
