import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/assigned_labor.dart';
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
import 'package:i_miner/models/plan_metraje_tl.dart';
import 'package:i_miner/services/mis_labores_service.dart';

class DialogoFormularioPerforacion extends StatefulWidget {
  final int operacionId;
  final int estadoId;
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
  List<_LongHolePlanLocation> ubicacionesPlanCompletas = [];
  List<TipoPerforacion> tiposPerforacionCompletos = [];
  List<AssignedLabor> laboresAsignadas = [];
  AssignedLabor? laborAsignadaSeleccionada;
  DimLabor? selectedLaborFromCatalogo;

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
        _cargarMisLabores(),
        _cargarCatalogos(),
        _cargarPlanMetrajeTL(),
      ]);

      await _resolverUbicacionesPlanMetrajeTL();
    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cargarMisLabores() async {
    try {
      final service = MisLaboresService();
      final labores = await service.fetchAssignedLabores(
        fecha: widget.fecha,
        processName: 'PERFORACIÓN TALADROS LARGOS',
      );

      if (!mounted) {
        return;
      }

      print('🔍 _cargarMisLabores → ${labores.length} labores cargadas');

      setState(() {
        laboresAsignadas = labores;
      });

      _sincronizarFrentePlanificado();
    } catch (e) {
      print('Error cargando mis labores: $e');
      usarFrentePlanificado = false;
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
      '🔍 _sincronizarFrentePlanificado → laboresAsignadas.isEmpty=${laboresAsignadas.isEmpty}, usarFrentePlanificado=$usarFrentePlanificado, ubicacionesPlanCompletas.length=${ubicacionesPlanCompletas.length}',
    );
    if (laboresAsignadas.isEmpty) {
      if (mounted) {
        setState(() {
          usarFrentePlanificado = false;
        });
      }
      return;
    }

    final laborInicial = _buscarLaborAsignadaInicial();
    laborAsignadaSeleccionada = laborInicial ?? laboresAsignadas.first;

    final datosInicialesTienenFrenteManual =
        (widget.datosIniciales?['labor']?.toString().isNotEmpty ?? false) &&
        laborInicial == null;

    usarFrentePlanificado = !datosInicialesTienenFrenteManual;
    if (usarFrentePlanificado) {
      _aplicarLaborAsignada(laborAsignadaSeleccionada!);
    }
  }

  AssignedLabor? _buscarLaborAsignadaInicial() {
    final laborActual = widget.datosIniciales?['labor']?.toString() ?? '';
    final tipoLaborActual =
        widget.datosIniciales?['tipo_labor']?.toString() ?? '';
    final nivelActual = widget.datosIniciales?['nivel']?.toString() ?? '';

    for (final labor in laboresAsignadas) {
      if (labor.laborNombre == laborActual &&
          labor.tipoLabor == tipoLaborActual &&
          labor.nivel == nivelActual) {
        return labor;
      }
    }

    return null;
  }

  void _aplicarLaborAsignada(AssignedLabor labor) {
    final ubicacion = _resolverUbicacionPlanificada(labor);

    setState(() {
      minaSeleccionada = ubicacion?.mina;
      zonaSeleccionada = ubicacion?.zona;
      areaSeleccionada = ubicacion?.area;
      faseSeleccionada = ubicacion?.fase;
      estructuraMineralSeleccionada = ubicacion?.estructuraMineral;
      nivelSeleccionado =
          ubicacion?.nivel ?? (labor.nivel.isEmpty ? null : labor.nivel);
      tipoLaborSeleccionado = labor.tipoLabor.isEmpty ? null : labor.tipoLabor;
      laborSeleccionado = labor.laborNombre.isEmpty ? null : labor.laborNombre;
      alaSeleccionado = ubicacion?.ala;
      laborAsignadaSeleccionada = labor;
    });
  }

  _LongHolePlanLocation? _resolverUbicacionPlanificada(AssignedLabor labor) {
    final tlPlan = planMetrajeTLCompletos.cast<PlanMetrajeTL?>().firstWhere(
      (p) => p?.laborId == labor.laborId,
      orElse: () => null,
    );
    if (tlPlan != null) {
      final result = _resolverUbicacionPorLaborId(tlPlan.laborId);
      if (result != null) return result;
    }

    for (final ubicacion in ubicacionesPlanCompletas) {
      final matchesAla = labor.ala.isEmpty || ubicacion.ala == labor.ala;
      final matchesEstructura =
          labor.estructuraMineral.isEmpty ||
          ubicacion.estructuraMineral == labor.estructuraMineral;

      if (ubicacion.tipoLabor == labor.tipoLabor &&
          ubicacion.labor == labor.laborNombre &&
          ubicacion.nivel == labor.nivel &&
          matchesAla &&
          matchesEstructura) {
        return ubicacion;
      }
    }

    return null;
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

  void _onLaborFromCatalogSelected(DimLabor labor) {
    final ubicacion = _resolverUbicacionPorLaborId(labor.laborId);
    setState(() {
      minaSeleccionada = ubicacion?.mina;
      zonaSeleccionada = ubicacion?.zona;
      areaSeleccionada = ubicacion?.area;
      faseSeleccionada = ubicacion?.fase;
      estructuraMineralSeleccionada = ubicacion?.estructuraMineral;
      nivelSeleccionado = ubicacion?.nivel;
      tipoLaborSeleccionado = ubicacion?.tipoLabor;
      laborSeleccionado = labor.nombreLabor;
      alaSeleccionado = null;
      selectedLaborFromCatalogo = labor;
    });
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
      tiposPerforacionCompletos = await dbHelper.getTiposPerforacionByProceso(
        "PERFORACIÓN TALADROS LARGOS",
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

  void _onAlaChanged(String? nuevoAla) {
    setState(() {
      alaSeleccionado = nuevoAla;
    });
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

        longitudBarraSeleccionada = widget.datosIniciales!['long_barras']
            ?.toString();
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

    final resolvedLaborId = usarFrentePlanificado
        ? laborAsignadaSeleccionada?.laborId
        : selectedLaborFromCatalogo?.laborId;

    Map<String, dynamic> datosFormulario = {
      'frente_origen': usarFrentePlanificado ? 'planificado' : 'otro_frente',
      'labor_id': resolvedLaborId,
      'mina': minaSeleccionada ?? '',
      'zona': zonaSeleccionada ?? '',
      'area': areaSeleccionada ?? '',
      'fase': faseSeleccionada ?? '',
      'estructura_mineral': estructuraMineralSeleccionada ?? '',
      'tipo_labor': tipoLaborSeleccionado ?? '',
      'labor': laborSeleccionado ?? '',
      'ala': alaSeleccionado ?? '',
      'nivel': nivelSeleccionado ?? '',
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
      'long_barras': double.tryParse(longitudBarraSeleccionada ?? '') ?? 0.0,
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (laboresAsignadas.isNotEmpty) ...[
                                      SegmentedButton<bool>(
                                        segments: const [
                                          ButtonSegment<bool>(
                                            value: true,
                                            label: Text('Frente planificado'),
                                          ),
                                          ButtonSegment<bool>(
                                            value: false,
                                            label: Text('Otro frente'),
                                          ),
                                        ],
                                        selected: {usarFrentePlanificado},
                                        onSelectionChanged: isEditable
                                            ? (selection) {
                                                final usePlanned =
                                                    selection.first;
                                                setState(() {
                                                  usarFrentePlanificado =
                                                      usePlanned;
                                                });
                                                if (usePlanned &&
                                                    laborAsignadaSeleccionada !=
                                                        null) {
                                                  _aplicarLaborAsignada(
                                                    laborAsignadaSeleccionada!,
                                                  );
                                                }
                                              }
                                            : null,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (usarFrentePlanificado &&
                                        laboresAsignadas.isNotEmpty)
                                      _buildPlannedFrontSelector()
                                    else
                                      _buildManualFrontSelectors(),
                                  ],
                                ),
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
                              _buildCompactDropdownField(
                                label: 'Longitud (pies)',
                                value: longitudBarraSeleccionada,
                                items: opcionesLongitudBarras,
                                onChanged: isEditable
                                    ? (value) => setState(
                                        () => longitudBarraSeleccionada = value,
                                      )
                                    : null,
                                icon: Icons.straighten,
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
  }) {
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
        keyboardType: keyboardType,
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              minimumSize: Size.zero,
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Guardar',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlannedFrontSelector() {
    final selected = laborAsignadaSeleccionada;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          initialValue: selected?.laborId,
          decoration: const InputDecoration(
            labelText: 'Labor asignada',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: laboresAsignadas.map((labor) {
            return DropdownMenuItem<int>(
              value: labor.laborId,
              child: Text(
                '${labor.laborNombre} | ${labor.nivel} | ${labor.estructuraMineral}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: isEditable
              ? (laborId) {
                  final match = laboresAsignadas.where(
                    (labor) => labor.laborId == laborId,
                  );
                  if (match.isNotEmpty) {
                    _aplicarLaborAsignada(match.first);
                  }
                }
              : null,
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Text(
            'Ubicacion: ${minaSeleccionada ?? '-'} / ${zonaSeleccionada ?? '-'} / ${areaSeleccionada ?? '-'} / ${faseSeleccionada ?? '-'}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Hoy tienes planificado: ${selected.estructuraMineral} / Nivel ${selected.nivel} / ${selected.tipoLabor} / ${selected.laborNombre}${alaSeleccionado?.isNotEmpty == true ? ' / Ala $alaSeleccionado' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (selected.valorPlanificado > 0)
            Text(
              'Valor planificado: ${selected.valorPlanificado}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ],
    );
  }

  Widget _buildManualFrontSelectors() {
    final planLaborIds = planMetrajeTLCompletos.map((p) => p.laborId).toSet();
    final laboresFiltradas =
        laboresCatalogo.where((l) => planLaborIds.contains(l.laborId)).toList()
          ..sort((a, b) => a.nombreLabor.compareTo(b.nombreLabor));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          initialValue: selectedLaborFromCatalogo?.laborId,
          decoration: const InputDecoration(
            labelText: 'Seleccionar labor',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: laboresFiltradas.map((labor) {
            return DropdownMenuItem<int>(
              value: labor.laborId,
              child: Text(labor.nombreLabor, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: isEditable
              ? (laborId) {
                  final match = laboresCatalogo.cast<DimLabor?>().firstWhere(
                    (l) => l?.laborId == laborId,
                    orElse: () => null,
                  );
                  if (match != null) {
                    _onLaborFromCatalogSelected(match);
                  }
                }
              : null,
        ),
        if (selectedLaborFromCatalogo != null) ...[
          const SizedBox(height: 8),
          Text(
            'Ubicación: ${minaSeleccionada ?? '-'} / ${zonaSeleccionada ?? '-'} / ${areaSeleccionada ?? '-'} / ${faseSeleccionada ?? '-'}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '${estructuraMineralSeleccionada ?? '-'} / Nivel ${nivelSeleccionado ?? '-'} / ${tipoLaborSeleccionado ?? '-'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildCompactDropdownField(
            label: 'Ala',
            value: alaSeleccionado,
            items: _uniqueSorted(alasCatalogo.map((a) => a.nombre)),
            onChanged: isEditable ? _onAlaChanged : null,
            icon: Icons.compare_arrows,
          ),
        ],
      ],
    );
  }

  Future<void> _resolverUbicacionesPlanMetrajeTL() async {
    final nuevasUbicaciones = <_LongHolePlanLocation>[];

    for (final plan in planMetrajeTLCompletos) {
      final location = _resolverUbicacionPorLaborId(plan.laborId);
      if (location != null) {
        nuevasUbicaciones.add(location);
      }
    }

    if (nuevasUbicaciones.isEmpty) return;

    setState(() {
      final existentes = ubicacionesPlanCompletas
          .map(
            (u) =>
                '${u.mina}|${u.zona}|${u.area}|${u.fase}|${u.estructuraMineral}|${u.nivel}|${u.tipoLabor}|${u.labor}',
          )
          .toSet();

      for (final ubicacion in nuevasUbicaciones) {
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

  List<String> _uniqueSorted(Iterable<String> values) {
    final unique = values
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    unique.sort();
    return unique;
  }
}
