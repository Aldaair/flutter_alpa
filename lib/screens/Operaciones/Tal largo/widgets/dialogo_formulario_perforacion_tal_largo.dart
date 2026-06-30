import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_miner/config/data/database_helper.dart';
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
import 'package:i_miner/models/plan_avance_th.dart';
import 'package:i_miner/models/plan_metraje_tl.dart';
import 'package:i_miner/models/plan_produccion.dart';

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

class _LongHolePlanLocation {
  const _LongHolePlanLocation({
    required this.mina,
    required this.zona,
    required this.area,
    required this.fase,
    required this.estructuraMineral,
    required this.nivel,
    required this.tipoLabor,
    required this.labor,
    required this.ala,
  });

  final String mina;
  final String zona;
  final String area;
  final String fase;
  final String estructuraMineral;
  final String nivel;
  final String tipoLabor;
  final String labor;
  final String ala;
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

  final int laborId;
  final int alaId;
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
  bool usarFrentePlanificado = true;

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

  final TextEditingController numBarrasController = TextEditingController();
  final TextEditingController longitudBarraController = TextEditingController();
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
  String? longitudBarraSeleccionada;
  int plannedLaborFieldResetKey = 0;
  int plannedAlaFieldResetKey = 0;
  int manualLaborFieldResetKey = 0;
  int manualAlaFieldResetKey = 0;

  // Opciones para los dropdowns
  List<String> opcionesTipoPerforacion = [];
  List<String> opcionesLongitudBarras = [];

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
  List<PlanMetrajeTL> planMetrajeTLCompletos = [];
  List<PlanAvanceTH> planesAvanceTHCompletos = [];
  List<PlanProduccion> planesProduccionCompletos = [];
  List<_LongHolePlanLocation> ubicacionesPlanCompletas = [];
  List<TipoPerforacion> tiposPerforacionCompletos = [];
  PlanMetrajeTL? plannedFrontSeleccionado;
  _ManualFrontOption? selectedManualFront;

  // Maps para RawAutocomplete
  final Map<String, _ManualFrontOption> _manualFrontMap = {};

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
      await Future.wait([
        _cargarTiposPerforacion(),
        _cargarLongitudBarras(),
        _cargarCatalogos(),
        _cargarPlanMetrajeTL(),
        _cargarPlanAvanceTH(),
        _cargarPlanProduccion(),
      ]);

      _rebuildManualFrontMap();

      await _resolverUbicacionesPlanMetrajeTL();
    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cargarPlanMetrajeTL() async {
    try {
      final dbHelper = DatabaseHelper();
      final data = await dbHelper.getPlanesMetrajeTL();
      setState(() {
        planMetrajeTLCompletos = data;
      });
      print('🔍 _cargarPlanMetrajeTL → ${data.length} registros');
    } catch (e) {
      print('Error cargando PlanMetrajeTL: $e');
    }
  }

  Future<void> _cargarPlanAvanceTH() async {
    try {
      final dbHelper = DatabaseHelper();
      final data = await dbHelper.getPlanesAvanceTH();
      setState(() {
        planesAvanceTHCompletos = data;
      });
    } catch (e) {
      print('Error cargando PlanAvanceTH: $e');
    }
  }

  Future<void> _cargarPlanProduccion() async {
    try {
      final dbHelper = DatabaseHelper();
      final data = await dbHelper.getPlanesProduccion();
      setState(() {
        planesProduccionCompletos = data;
      });
    } catch (e) {
      print('Error cargando PlanProduccion: $e');
    }
  }

  Future<void> _cargarCatalogos() async {
    try {
      final dbHelper = DatabaseHelper();
      final results = await Future.wait([
        dbHelper.getMinas(),
        dbHelper.getDimZonas(),
        dbHelper.getAreas(),
        dbHelper.getFases(),
        dbHelper.getTiposLabor(),
        dbHelper.getEstructurasMinerales(),
        dbHelper.getNiveles(),
        dbHelper.getAlas(),
        dbHelper.getLabores(),
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

  void _sincronizarFrentePlanificado() {
    print(
      '🔍 _sincronizarFrentePlanificado → plannedOptions=${planMetrajeTLCompletos.length}, usarFrentePlanificado=$usarFrentePlanificado, ubicacionesPlanCompletas.length=${ubicacionesPlanCompletas.length}',
    );
    if (planMetrajeTLCompletos.isEmpty) {
      return;
    }

    final laborInicial = _buscarLaborPlanInicial();
    plannedFrontSeleccionado = laborInicial ?? planMetrajeTLCompletos.first;

    final datosInicialesTienenFrenteManual =
        (widget.datosIniciales?['labor']?.toString().isNotEmpty ?? false) &&
        laborInicial == null;

    usarFrentePlanificado = !datosInicialesTienenFrenteManual;
    if (usarFrentePlanificado && plannedFrontSeleccionado != null) {
      _aplicarLaborPlan(plannedFrontSeleccionado!);
    }
  }

  PlanMetrajeTL? _buscarLaborPlanInicial() {
    final laborActual = widget.datosIniciales?['labor']?.toString() ?? '';
    final tipoLaborActual =
        widget.datosIniciales?['tipo_labor']?.toString() ?? '';
    final alaActual = widget.datosIniciales?['ala']?.toString() ?? '';

    for (final plan in planMetrajeTLCompletos) {
      final matchesAla = alaActual.isEmpty || plan.alaNombre == alaActual;
      if (plan.laborNombre == laborActual &&
          plan.tipoLaborNombre == tipoLaborActual &&
          matchesAla) {
        return plan;
      }
    }

    return null;
  }

  void _aplicarLaborPlan(PlanMetrajeTL plan) {
    final ubicacion = _buildPlanLocation(plan);
    setState(() {
      minaSeleccionada = ubicacion.mina;
      zonaSeleccionada = ubicacion.zona;
      areaSeleccionada = ubicacion.area;
      faseSeleccionada = ubicacion.fase;
      estructuraMineralSeleccionada = ubicacion.estructuraMineral;
      nivelSeleccionado = ubicacion.nivel;
      tipoLaborSeleccionado = ubicacion.tipoLabor;
      laborSeleccionado = ubicacion.labor;
      alaSeleccionado = ubicacion.ala;
      plannedFrontSeleccionado = plan;
    });
  }

  _LongHolePlanLocation _buildPlanLocation(PlanMetrajeTL plan) {
    return _LongHolePlanLocation(
      mina: plan.minaNombre,
      zona: plan.zonaNombre,
      area: plan.areaNombre,
      fase: plan.faseNombre,
      estructuraMineral: plan.estructuraMineralNombre,
      nivel: plan.nivelNombre,
      tipoLabor: plan.tipoLaborNombre,
      labor: plan.laborNombre,
      ala: plan.alaNombre,
    );
  }

  _LongHolePlanLocation? _resolverUbicacionPorLaborId(int laborId) {
    final labor = laboresCatalogo.cast<DimLabor?>().firstWhere(
      (l) => l?.laborId == laborId,
      orElse: () => null,
    );
    if (labor == null) return null;

    final mina = minasCatalogo.cast<DimMina?>().firstWhere(
      (m) => m?.minaId == labor.minaId,
      orElse: () => null,
    );
    final zona = zonasCatalogo.cast<DimZona?>().firstWhere(
      (z) => z?.zonaId == labor.zonaId,
      orElse: () => null,
    );
    final area = areasCatalogo.cast<DimArea?>().firstWhere(
      (a) => a?.areaId == labor.areaId,
      orElse: () => null,
    );
    final fase = fasesCatalogo.cast<DimFase?>().firstWhere(
      (f) => f?.faseId == labor.faseId,
      orElse: () => null,
    );
    final tipoLabor = tiposLaborCatalogo.cast<DimTipoLabor?>().firstWhere(
      (t) => t?.tipoLaborId == labor.tipoLaborId,
      orElse: () => null,
    );
    final estructura = estructurasMineralesCatalogo
        .cast<DimEstructuraMineral?>()
        .firstWhere(
          (e) => e?.estructuraMineralId == labor.estructuraMineralId,
          orElse: () => null,
        );
    final nivel = nivelesCatalogo.cast<DimNivel?>().firstWhere(
      (n) => n?.nivelId == labor.nivelId,
      orElse: () => null,
    );

    if (mina == null ||
        zona == null ||
        area == null ||
        fase == null ||
        tipoLabor == null ||
        estructura == null ||
        nivel == null) {
      return null;
    }

    return _LongHolePlanLocation(
      mina: mina.nombre,
      zona: zona.nombre,
      area: area.nombre,
      fase: fase.nombre,
      estructuraMineral: estructura.nombre,
      nivel: nivel.nombre,
      tipoLabor: tipoLabor.nombre,
      labor: labor.nombreLabor,
      ala: '',
    );
  }

  void _rebuildManualFrontMap() {
    _manualFrontMap.clear();

    void registerOption({
      required int laborId,
      required int alaId,
      required String tipoLabor,
      required String labor,
      required String ala,
      required String mina,
      required String zona,
      required String area,
      required String fase,
      required String estructuraMineral,
      required String nivel,
    }) {
      if (tipoLabor.trim().isEmpty || labor.trim().isEmpty || ala.trim().isEmpty) {
        return;
      }
      final label = '${tipoLabor.trim()} - ${labor.trim()} - ${ala.trim()}';
      _manualFrontMap[label] = _ManualFrontOption(
        laborId: laborId,
        alaId: alaId,
        tipoLabor: tipoLabor.trim(),
        labor: labor.trim(),
        ala: ala.trim(),
        mina: mina.trim(),
        zona: zona.trim(),
        area: area.trim(),
        fase: fase.trim(),
        estructuraMineral: estructuraMineral.trim(),
        nivel: nivel.trim(),
      );
    }

    for (final plan in planMetrajeTLCompletos) {
      registerOption(
        laborId: plan.laborId,
        alaId: plan.alaId,
        tipoLabor: plan.tipoLaborNombre,
        labor: plan.laborNombre,
        ala: plan.alaNombre,
        mina: plan.minaNombre,
        zona: plan.zonaNombre,
        area: plan.areaNombre,
        fase: plan.faseNombre,
        estructuraMineral: plan.estructuraMineralNombre,
        nivel: plan.nivelNombre,
      );
    }

    for (final plan in planesAvanceTHCompletos) {
      registerOption(
        laborId: plan.laborId,
        alaId: plan.alaId,
        tipoLabor: plan.tipoLaborNombre,
        labor: plan.laborNombre,
        ala: plan.alaNombre,
        mina: plan.minaNombre,
        zona: plan.zonaNombre,
        area: plan.areaNombre,
        fase: plan.faseNombre,
        estructuraMineral: plan.estructuraMineralNombre,
        nivel: plan.nivelNombre,
      );
    }

    for (final plan in planesProduccionCompletos) {
      registerOption(
        laborId: plan.laborId,
        alaId: plan.alaId,
        tipoLabor: plan.tipoLaborNombre,
        labor: plan.laborNombre,
        ala: plan.alaNombre,
        mina: plan.minaNombre,
        zona: plan.zonaNombre,
        area: plan.areaNombre,
        fase: plan.faseNombre,
        estructuraMineral: plan.estructuraMineralNombre,
        nivel: plan.nivelNombre,
      );
    }

    if (!usarFrentePlanificado) {
      final currentLabel = _buildManualFrontLabelFromState();
      if (currentLabel != null) {
        selectedManualFront = _manualFrontMap[currentLabel];
      }
    }
  }

  void _clearManualResolvedLocation() {
    minaSeleccionada = null;
    zonaSeleccionada = null;
    areaSeleccionada = null;
    faseSeleccionada = null;
    estructuraMineralSeleccionada = null;
    nivelSeleccionado = null;
  }

  String? _buildManualFrontLabelFromState() {
    final tipoLabor = tipoLaborSeleccionado?.trim();
    final labor = laborSeleccionado?.trim();
    final ala = alaSeleccionado?.trim();
    if (tipoLabor == null || tipoLabor.isEmpty) return null;
    if (labor == null || labor.isEmpty) return null;
    if (ala == null || ala.isEmpty) return null;
    return '$tipoLabor - $labor - $ala';
  }

  _ManualFrontOption? _resolveManualFrontSelection() {
    final label = _buildManualFrontLabelFromState();
    if (label == null) {
      return null;
    }

    return _manualFrontMap[label];
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
    });
  }

  PlanMetrajeTL? _resolveSelectedPlannedFront() {
    final tipoLabor = tipoLaborSeleccionado?.trim();
    final labor = laborSeleccionado?.trim();
    final ala = alaSeleccionado?.trim();
    if (tipoLabor == null || tipoLabor.isEmpty) return null;
    if (labor == null || labor.isEmpty) return null;
    if (ala == null || ala.isEmpty) return null;

    for (final plan in planMetrajeTLCompletos) {
      if (plan.tipoLaborNombre == tipoLabor &&
          plan.laborNombre == labor &&
          plan.alaNombre == ala) {
        return plan;
      }
    }
    return null;
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
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
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

  Future<void> _cargarLongitudBarras() async {
    try {
      final dbHelper = DatabaseHelper();
      final data = await dbHelper.getLongitudBarrasPorProceso(
        "PERFORACIÓN TALADROS LARGOS",
      );
      final lista =
          data.map((e) => e['longitud_pies'].toString()).toSet().toList()
            ..sort((a, b) => double.parse(a).compareTo(double.parse(b)));
      setState(() {
        opcionesLongitudBarras = lista;
      });
    } catch (e) {
      print("Error cargando longitudes: $e");
    }
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

        longitudBarraController.text =
            widget.datosIniciales!['long_barras']?.toString() ?? '';
        numBarrasController.text =
            widget.datosIniciales!['num_barras']?.toString() ?? '';
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

    if (laborSeleccionado == null || laborSeleccionado!.isEmpty) {
      _mostrarSnackbar('Debe seleccionar un frente de trabajo', Colors.orange);
      return;
    }

    final plannedFront = usarFrentePlanificado ? _resolveSelectedPlannedFront() : null;
    final manualFront = usarFrentePlanificado ? null : _resolveManualFrontSelection();

    if (usarFrentePlanificado && plannedFront == null) {
      _mostrarSnackbar(
        'Debe seleccionar una opcion valida en Labor Plan',
        Colors.orange,
      );
      return;
    }

    if (!usarFrentePlanificado && manualFront == null) {
      _mostrarSnackbar(
        'Debe seleccionar una opcion valida en Otro Frente',
        Colors.orange,
      );
      return;
    }

    final manualUbicacion = manualFront != null
        ? _LongHolePlanLocation(
            mina: manualFront.mina,
            zona: manualFront.zona,
            area: manualFront.area,
            fase: manualFront.fase,
            estructuraMineral: manualFront.estructuraMineral,
            nivel: manualFront.nivel,
            tipoLabor: manualFront.tipoLabor,
            labor: manualFront.labor,
            ala: manualFront.ala,
          )
        : null;
    final planUbicacion = plannedFront != null ? _buildPlanLocation(plannedFront) : null;

    final resolvedLaborId = usarFrentePlanificado
        ? plannedFront?.laborId
        : manualFront?.laborId;

    final mina = usarFrentePlanificado
        ? planUbicacion?.mina ?? minaSeleccionada
        : manualUbicacion?.mina ?? minaSeleccionada;
    final zona = usarFrentePlanificado
        ? planUbicacion?.zona ?? zonaSeleccionada
        : manualUbicacion?.zona ?? zonaSeleccionada;
    final area = usarFrentePlanificado
        ? planUbicacion?.area ?? areaSeleccionada
        : manualUbicacion?.area ?? areaSeleccionada;
    final fase = usarFrentePlanificado
        ? planUbicacion?.fase ?? faseSeleccionada
        : manualUbicacion?.fase ?? faseSeleccionada;
    final estructuraMineral = usarFrentePlanificado
        ? planUbicacion?.estructuraMineral ?? estructuraMineralSeleccionada
        : manualUbicacion?.estructuraMineral ?? estructuraMineralSeleccionada;
    final nivel = usarFrentePlanificado
        ? planUbicacion?.nivel ?? nivelSeleccionado
        : manualUbicacion?.nivel ?? nivelSeleccionado;
    final tipoLabor = usarFrentePlanificado
        ? plannedFront?.tipoLaborNombre ?? tipoLaborSeleccionado
        : manualFront?.tipoLabor ?? manualUbicacion?.tipoLabor;

    Map<String, dynamic> datosFormulario = {
      'frente_origen': usarFrentePlanificado ? 'planificado' : 'otro_frente',
      'labor_id': resolvedLaborId,
      'mina': mina ?? '',
      'zona': zona ?? '',
      'area': area ?? '',
      'fase': fase ?? '',
      'estructura_mineral': estructuraMineral ?? '',
      'tipo_labor': tipoLabor ?? '',
      'labor': usarFrentePlanificado
          ? (plannedFront?.laborNombre ?? laborSeleccionado ?? '')
          : (manualFront?.labor ?? laborSeleccionado ?? ''),
      'ala': usarFrentePlanificado
          ? (plannedFront?.alaNombre ?? alaSeleccionado ?? '')
          : (manualFront?.ala ?? alaSeleccionado ?? ''),
      'ala_id': usarFrentePlanificado
          ? _obtenerIdAla(alaSeleccionado)
          : manualFront?.alaId,
      'nivel': nivel ?? '',
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
      'long_barras': double.tryParse(longitudBarraController.text) ?? 0.0,
      'num_barras': int.tryParse(numBarrasController.text) ?? 0,
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

  int? _obtenerIdAla(String? nombre) {
    if (nombre == null || nombre.isEmpty) return null;
    try {
      return alasCatalogo.firstWhere((a) => a.nombre == nombre).alaId;
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
    numBarrasController.dispose();
    longitudBarraController.dispose();
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
                          // SECCIÓN 1: Ubicación con NUEVO ORDEN
                          _buildSeccionCompacta(
                            icon: Icons.location_on,
                            titulo: 'Ubicación',
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SegmentedButton<bool>(
                                    segments: const [
                                      ButtonSegment<bool>(
                                        value: true,
                                        label: Text('Labor Plan'),
                                      ),
                                      ButtonSegment<bool>(
                                        value: false,
                                        label: Text('Otro Frente'),
                                      ),
                                    ],
                                    selected: {usarFrentePlanificado},
                                    onSelectionChanged: isEditable
                                        ? (selection) {
                                            final usePlanned = selection.first;
                                            setState(() {
                                              usarFrentePlanificado =
                                                  usePlanned;
                                            });
                                            if (usePlanned &&
                                                plannedFrontSeleccionado !=
                                                    null) {
                                              _aplicarLaborPlan(
                                                plannedFrontSeleccionado!,
                                              );
                                            }
                                          }
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  if (usarFrentePlanificado)
                                    _buildPlannedFrontSelector()
                                  else
                                    _buildManualFrontSelectors(),
                                ],
                              ),
                            ],
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

                          // Barras
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
                              _buildCompactTextField(
                                label: 'N° Barras',
                                controller: numBarrasController,
                                icon: Icons.format_list_numbered,
                              ),
                            ],
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
            style: const TextStyle(fontSize: 13),
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
        keyboardType:
            allowDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : keyboardType,
        inputFormatters: [formatter],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
                    fontSize: 11,
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
                        fontSize: 11,
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

  Widget _buildPlannedFrontSelector() {
    final selected = _resolveSelectedPlannedFront() ?? plannedFrontSeleccionado;
    final hasTipoLaborSeleccionado =
        tipoLaborSeleccionado != null && tipoLaborSeleccionado!.trim().isNotEmpty;
    final hasLaborSeleccionada =
        laborSeleccionado != null && laborSeleccionado!.trim().isNotEmpty;
    final plannedTipos = planMetrajeTLCompletos
        .map((plan) => plan.tipoLaborNombre)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final plannedLabores = planMetrajeTLCompletos
        .where(
          (plan) =>
              tipoLaborSeleccionado == null ||
              tipoLaborSeleccionado!.isEmpty ||
              plan.tipoLaborNombre == tipoLaborSeleccionado,
        )
        .map((plan) => plan.laborNombre)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final plannedAlas = planMetrajeTLCompletos
        .where(
          (plan) =>
              (tipoLaborSeleccionado == null ||
                  tipoLaborSeleccionado!.isEmpty ||
                  plan.tipoLaborNombre == tipoLaborSeleccionado) &&
              (laborSeleccionado == null ||
                  laborSeleccionado!.isEmpty ||
                  plan.laborNombre == laborSeleccionado),
        )
        .map((plan) => plan.alaNombre)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThreeAutocompleteRow(
          first: _buildSearchableAutocompleteField(
            label: 'Tipo Labor',
            hintText: 'Buscar tipo labor del plan...',
            options: plannedTipos,
            selectedValue: tipoLaborSeleccionado,
            onChanged: (value) {
              setState(() {
                tipoLaborSeleccionado = value;
                laborSeleccionado = null;
                alaSeleccionado = null;
                plannedFrontSeleccionado = null;
                plannedLaborFieldResetKey++;
                plannedAlaFieldResetKey++;
                _clearManualResolvedLocation();
              });
            },
            onSelected: (value) {
              setState(() {
                tipoLaborSeleccionado = value;
                laborSeleccionado = null;
                alaSeleccionado = null;
                plannedFrontSeleccionado = null;
                plannedLaborFieldResetKey++;
                plannedAlaFieldResetKey++;
                _clearManualResolvedLocation();
              });
            },
          ),
          second: _buildSearchableAutocompleteField(
            label: 'Labor',
            hintText: 'Buscar labor del plan...',
            options: plannedLabores,
            selectedValue: laborSeleccionado,
            enabled: hasTipoLaborSeleccionado,
            resetKey: plannedLaborFieldResetKey,
            onChanged: (value) {
              setState(() {
                laborSeleccionado = value;
                alaSeleccionado = null;
                plannedFrontSeleccionado = null;
                plannedAlaFieldResetKey++;
                _clearManualResolvedLocation();
              });
            },
            onSelected: (value) {
              setState(() {
                laborSeleccionado = value;
                alaSeleccionado = null;
                plannedFrontSeleccionado = null;
                plannedAlaFieldResetKey++;
                _clearManualResolvedLocation();
              });
            },
          ),
          third: _buildSearchableAutocompleteField(
            label: 'Ala',
            hintText: 'Buscar ala del plan...',
            options: plannedAlas,
            selectedValue: alaSeleccionado,
            enabled: hasLaborSeleccionada,
            resetKey: plannedAlaFieldResetKey,
            onChanged: (value) {
              setState(() {
                alaSeleccionado = value;
                plannedFrontSeleccionado = null;
                _clearManualResolvedLocation();
              });
            },
            onSelected: (value) {
              setState(() {
                alaSeleccionado = value;
              });
              final plan = _resolveSelectedPlannedFront();
              if (plan != null) {
                _aplicarLaborPlan(plan);
              }
            },
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Text(
            _buildManualLocationSummary(),
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Plan del periodo: ${selected.estructuraMineralNombre} / Nivel ${selected.nivelNombre} / ${selected.tipoLaborNombre} / ${selected.laborNombre}${selected.alaNombre.isNotEmpty ? ' / Ala ${selected.alaNombre}' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            'Ancho veta: ${selected.anchoVetaMetros} / Minado sem: ${selected.anchoMinadoSemMetros} / Minado mes: ${selected.anchoMinadoMesMetros}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildManualFrontSelectors() {
    final selected = _resolveManualFrontSelection() ?? selectedManualFront;
    final hasTipoLaborSeleccionado =
        tipoLaborSeleccionado != null && tipoLaborSeleccionado!.trim().isNotEmpty;
    final hasLaborSeleccionada =
        laborSeleccionado != null && laborSeleccionado!.trim().isNotEmpty;
    final manualTipos = _manualFrontMap.values
        .map((option) => option.tipoLabor)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final manualLabores = _manualFrontMap.values
        .where(
          (option) =>
              tipoLaborSeleccionado == null ||
              tipoLaborSeleccionado!.isEmpty ||
              option.tipoLabor == tipoLaborSeleccionado,
        )
        .map((option) => option.labor)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final manualAlas = _manualFrontMap.values
        .where(
          (option) =>
              (tipoLaborSeleccionado == null ||
                  tipoLaborSeleccionado!.isEmpty ||
                  option.tipoLabor == tipoLaborSeleccionado) &&
              (laborSeleccionado == null ||
                  laborSeleccionado!.isEmpty ||
                  option.labor == laborSeleccionado),
        )
        .map((option) => option.ala)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThreeAutocompleteRow(
          first: _buildSearchableAutocompleteField(
            label: 'Tipo Labor',
            hintText: 'Buscar tipo labor...',
            options: manualTipos,
            selectedValue: tipoLaborSeleccionado,
            onChanged: (value) {
              setState(() {
                tipoLaborSeleccionado = value;
                laborSeleccionado = null;
                alaSeleccionado = null;
                selectedManualFront = null;
                manualLaborFieldResetKey++;
                manualAlaFieldResetKey++;
                _clearManualResolvedLocation();
              });
            },
            onSelected: (value) {
              setState(() {
                tipoLaborSeleccionado = value;
                laborSeleccionado = null;
                alaSeleccionado = null;
                selectedManualFront = null;
                manualLaborFieldResetKey++;
                manualAlaFieldResetKey++;
                _clearManualResolvedLocation();
              });
            },
          ),
          second: _buildSearchableAutocompleteField(
            label: 'Labor',
            hintText: 'Buscar labor...',
            options: manualLabores,
            selectedValue: laborSeleccionado,
            enabled: hasTipoLaborSeleccionado,
            resetKey: manualLaborFieldResetKey,
            onChanged: (value) {
              setState(() {
                laborSeleccionado = value;
                alaSeleccionado = null;
                selectedManualFront = null;
                manualAlaFieldResetKey++;
                _clearManualResolvedLocation();
              });
            },
            onSelected: (value) {
              setState(() {
                laborSeleccionado = value;
                alaSeleccionado = null;
                selectedManualFront = null;
                manualAlaFieldResetKey++;
                _clearManualResolvedLocation();
              });
            },
          ),
          third: _buildSearchableAutocompleteField(
            label: 'Ala',
            hintText: 'Buscar ala...',
            options: manualAlas,
            selectedValue: alaSeleccionado,
            enabled: hasLaborSeleccionada,
            resetKey: manualAlaFieldResetKey,
            onChanged: (value) {
              setState(() {
                alaSeleccionado = value;
                selectedManualFront = null;
                _clearManualResolvedLocation();
              });
            },
            onSelected: (value) {
              setState(() {
                alaSeleccionado = value;
              });
              final option = _resolveManualFrontSelection();
              if (option != null) {
                _aplicarManualFront(option);
              }
            },
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Text(
            _buildManualLocationSummary(),
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '${selected.estructuraMineral} / Nivel ${selected.nivel} / ${selected.tipoLabor} / ${selected.labor}${selected.ala.isNotEmpty ? ' / Ala ${selected.ala}' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Future<void> _resolverUbicacionesPlanMetrajeTL() async {
    setState(() {
      ubicacionesPlanCompletas.clear();
      final existentes = ubicacionesPlanCompletas
          .map(
            (u) =>
                '${u.mina}|${u.zona}|${u.area}|${u.fase}|${u.estructuraMineral}|${u.nivel}|${u.tipoLabor}|${u.labor}',
          )
          .toSet();

      for (final plan in planMetrajeTLCompletos) {
        final ubicacion = _buildPlanLocation(plan);
        final key =
            '${ubicacion.mina}|${ubicacion.zona}|${ubicacion.area}|${ubicacion.fase}|${ubicacion.estructuraMineral}|${ubicacion.nivel}|${ubicacion.tipoLabor}|${ubicacion.labor}';
        if (!existentes.contains(key)) {
          ubicacionesPlanCompletas.add(ubicacion);
          existentes.add(key);
        }
      }
    });

    _sincronizarFrentePlanificado();
  }

  Widget _buildThreeAutocompleteRow({
    required Widget first,
    required Widget second,
    required Widget third,
  }) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second),
        const SizedBox(width: 8),
        Expanded(child: third),
      ],
    );
  }

}
