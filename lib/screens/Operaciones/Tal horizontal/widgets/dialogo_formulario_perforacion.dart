import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/DimAla.dart';
import 'package:i_miner/models/DimLabor.dart';
import 'package:i_miner/models/DimNivel.dart';
import 'package:i_miner/models/DimTipoLabor.dart';
import 'package:i_miner/models/assigned_labor.dart';
import 'package:i_miner/models/TipoPerforacion.dart';
import 'package:i_miner/models/plan_avance_th.dart';
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

class _DialogoFormularioPerforacionState
    extends State<DialogoFormularioPerforacion> {
  bool isEditable = false;
  bool isLoading = true;
  bool usarFrentePlanificado = true;

  // Controladores para los campos de texto
  final TextEditingController talProdController = TextEditingController();
  final TextEditingController talRimadosController = TextEditingController();
  final TextEditingController talAlivioController = TextEditingController();
  final TextEditingController talRepasoController = TextEditingController();
  final TextEditingController numBarrasController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();

  // Variables para los campos seleccionables

  String? tipoLaborSeleccionado; // 1º
  String? laborSeleccionado; // 2º
  String? alaSeleccionado; // 3º
  String? nivelSeleccionado;

  String? tipoPerforacionSeleccionado;

  // Opciones para los dropdowns (ahora vienen de la BD)
  List<String> opcionesTipoPerforacion = [];

  List<String> opcionesLongitudBarras = [];
  String? longitudBarraSeleccionada;

  // Almacenar objetos completos para referencia
  List<PlanAvanceTH> planesAvanceCompletos = [];
  List<TipoPerforacion> tiposPerforacionCompletos = [];
  List<DimTipoLabor> tiposLaborCatalogo = [];
  List<DimNivel> nivelesCatalogo = [];
  List<DimAla> alasCatalogo = [];
  List<DimLabor> laboresCatalogo = [];
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
        _cargarPlanAvanceTH(),
      ]);
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
        processName: 'PERFORACIÓN HORIZONTAL',
      );

      if (!mounted) return;

      setState(() {
        laboresAsignadas = labores;
      });

      _sincronizarFrentePlanificado();
    } catch (e) {
      print('Error cargando mis labores: $e');
      usarFrentePlanificado = false;
    }
  }

  void _sincronizarFrentePlanificado() {
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
    final ala = labor.ala.isNotEmpty
        ? labor.ala
        : (widget.datosIniciales?['ala']?.toString().isNotEmpty == true
              ? widget.datosIniciales!['ala'].toString()
              : null);
    setState(() {
      tipoLaborSeleccionado = labor.tipoLabor.isEmpty ? null : labor.tipoLabor;
      laborSeleccionado = labor.laborNombre.isEmpty ? null : labor.laborNombre;
      nivelSeleccionado = labor.nivel.isEmpty ? null : labor.nivel;
      alaSeleccionado = ala;
      laborAsignadaSeleccionada = labor;
    });
  }

  Future<void> _cargarLongitudBarras() async {
    try {
      final dbHelper = DatabaseHelper();

      final data = await dbHelper.getLongitudBarrasPorProceso(
        "PERFORACIÓN HORIZONTAL",
      );

      final lista =
          data.map((e) => e['longitud_pies'].toString()).toSet().toList()
            ..sort((a, b) => double.parse(a).compareTo(double.parse(b)));

      setState(() {
        opcionesLongitudBarras = lista;
      });

      print("Longitudes cargadas: $opcionesLongitudBarras");
    } catch (e) {
      print("Error cargando longitudes: $e");
    }
  }

  Future<void> _cargarCatalogos() async {
    try {
      final dbHelper = DatabaseHelper();
      final results = await Future.wait([
        dbHelper.getTiposLabor(),
        dbHelper.getNiveles(),
        dbHelper.getAlas(),
        dbHelper.getLabores(),
      ]);

      if (!mounted) return;

      setState(() {
        tiposLaborCatalogo = results[0] as List<DimTipoLabor>;
        nivelesCatalogo = results[1] as List<DimNivel>;
        alasCatalogo = results[2] as List<DimAla>;
        laboresCatalogo = results[3] as List<DimLabor>;
        if (selectedLaborFromCatalogo == null && laborSeleccionado != null) {
          selectedLaborFromCatalogo = _resolveSelectedLaborFromCatalog(
            laborSeleccionado,
          );
        }
      });
    } catch (e) {
      print('Error cargando catálogos: $e');
    }
  }

  Future<void> _cargarPlanAvanceTH() async {
    try {
      final dbHelper = DatabaseHelper();
      final data = await dbHelper.getPlanesAvanceTH();
      setState(() {
        planesAvanceCompletos = data;
      });
      print('🔍 _cargarPlanAvanceTH → ${data.length} registros');
    } catch (e) {
      print('Error cargando PlanAvanceTH: $e');
    }
  }

  // ✅ Cargar tipos de perforación
  Future<void> _cargarTiposPerforacion() async {
    try {
      final dbHelper = DatabaseHelper();
      tiposPerforacionCompletos = await dbHelper.getTiposPerforacionByProceso(
        "PERFORACIÓN HORIZONTAL",
      );

      final lista =
          tiposPerforacionCompletos
              .map((t) => t.nombre ?? '')
              .where((n) => n.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      setState(() {
        opcionesTipoPerforacion = lista;
      });

      print('Tipos de perforación cargados: $opcionesTipoPerforacion');
    } catch (e) {
      print("Error cargando tipos de perforación: $e");
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

  DimLabor? _resolveSelectedLaborFromCatalog(String? laborNombre) {
    if (laborNombre == null || laborNombre.isEmpty) return null;

    for (final labor in laboresCatalogo) {
      if (labor.nombreLabor == laborNombre) {
        return labor;
      }
    }

    return null;
  }

  String? _resolveTipoLaborNombre(DimLabor labor) {
    final tipoLabor = tiposLaborCatalogo.cast<DimTipoLabor?>().firstWhere(
      (item) => item?.tipoLaborId == labor.tipoLaborId,
      orElse: () => null,
    );
    return tipoLabor?.nombre;
  }

  String? _resolveNivelNombre(DimLabor labor) {
    final nivel = nivelesCatalogo.cast<DimNivel?>().firstWhere(
      (item) => item?.nivelId == labor.nivelId,
      orElse: () => null,
    );
    return nivel?.nombre;
  }

  void _onLaborFromCatalogSelected(DimLabor labor) {
    setState(() {
      tipoLaborSeleccionado = _resolveTipoLaborNombre(labor);
      laborSeleccionado = labor.nombreLabor;
      nivelSeleccionado = _resolveNivelNombre(labor);
      alaSeleccionado = null;
      selectedLaborFromCatalogo = labor;
    });
  }

  void _onAlaChanged(String? nuevoAla) {
    setState(() {
      alaSeleccionado = nuevoAla;
    });
  }

  void _cargarDatosIniciales() {
    if (widget.datosIniciales != null) {
      setState(() {
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
        selectedLaborFromCatalogo = _resolveSelectedLaborFromCatalog(
          laborSeleccionado,
        );

        talProdController.text = widget.datosIniciales!['tal_prod'] ?? '';
        talRimadosController.text = widget.datosIniciales!['tal_rimados'] ?? '';
        talAlivioController.text = widget.datosIniciales!['tal_alivio'] ?? '';
        talRepasoController.text = widget.datosIniciales!['tal_repaso'] ?? '';
        longitudBarraSeleccionada = widget.datosIniciales!['long_barras']
            ?.toString();
        numBarrasController.text = widget.datosIniciales!['num_barras'] ?? '';
        observacionesController.text =
            widget.datosIniciales!['observaciones'] ?? '';
      });
    }
  }

  Future<void> _guardarDatos() async {
    // Validaciones básicas
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

    final existingLaborIdValue = widget.datosIniciales != null
        ? widget.datosIniciales!['labor_id']
        : null;
    final existingLaborId = existingLaborIdValue is int
        ? existingLaborIdValue
        : int.tryParse(existingLaborIdValue?.toString() ?? '');

    final resolvedLaborId = usarFrentePlanificado
        ? laborAsignadaSeleccionada?.laborId
        : (selectedLaborFromCatalogo?.laborId ?? existingLaborId);

    if (resolvedLaborId == null) {
      _mostrarSnackbar(
        'No se pudo resolver la labor seleccionada',
        Colors.orange,
      );
      return;
    }

    Map<String, dynamic> datosFormulario = {
      'labor_id': resolvedLaborId,
      'frente_origen': usarFrentePlanificado ? 'planificado' : 'otro_frente',
      'tipo_labor': tipoLaborSeleccionado ?? '',
      'labor': laborSeleccionado ?? '',
      'ala': alaSeleccionado ?? '',
      'nivel': nivelSeleccionado ?? '',
      'tal_prod': int.tryParse(talProdController.text) ?? 0,
      'tal_rimados': int.tryParse(talRimadosController.text) ?? 0,
      'tal_alivio': int.tryParse(talAlivioController.text) ?? 0,
      'tal_repaso': int.tryParse(talRepasoController.text) ?? 0,
      'long_barras': double.tryParse(longitudBarraSeleccionada ?? '') ?? 0.0,
      'num_barras': int.tryParse(numBarrasController.text) ?? 0,
      'tipo_perforacion': tipoPerforacionSeleccionado ?? '',

      // También guardar el ID si es necesario
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
    talProdController.dispose();
    talRimadosController.dispose();
    talAlivioController.dispose();
    talRepasoController.dispose();
    numBarrasController.dispose();
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
          maxHeight:
              MediaQuery.of(context).size.height *
              0.9, // 90% de la altura de la pantalla
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

                  // Contenido con scroll
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // SECCIÓN 1: Ubicación (con datos de Plan Avance)
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

                          // SECCIÓN 2: Taladros
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

                          // SECCIÓN 3: Barras
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
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 1,
                                child: const SizedBox.shrink(),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 1,
                                child: const SizedBox.shrink(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // SECCIÓN 4: Tipo de Perforación
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
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 1,
                                child: const SizedBox.shrink(),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 1,
                                child: const SizedBox.shrink(),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 1,
                                child: const SizedBox.shrink(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // SECCIÓN 5: Observaciones (NUEVA)
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
          height: 80, // Altura fija para el campo de observaciones
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: observacionesController,
            enabled: isEditable,
            maxLines: null, // Permite múltiples líneas
            expands: true, // Se expande para llenar el espacio
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Ingrese observaciones...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                ), // Ajuste para alinear el icono
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

  Widget _buildManualFrontSelectors() {
    final planLaborIds = planesAvanceCompletos.map((p) => p.laborId).toSet();
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
            '${tipoLaborSeleccionado ?? '-'} / Nivel ${nivelSeleccionado ?? '-'}',
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

  List<String> _uniqueSorted(Iterable<String> values) {
    final unique = values
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    unique.sort();
    return unique;
  }
}
