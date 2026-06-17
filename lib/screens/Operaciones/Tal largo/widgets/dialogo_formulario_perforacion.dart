import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/PlanProduccion.dart';
import 'package:i_miner/models/PlanMetraje.dart';
import 'package:i_miner/models/TipoPerforacion.dart';

class DialogoFormularioPerforacion extends StatefulWidget {
  final int operacionId;
  final int estadoId;
  final Map<String, dynamic>? datosIniciales;
  final String estado;
  final Color primaryColor;
  final Function(Map<String, dynamic>) onGuardar;

  const DialogoFormularioPerforacion({
    Key? key,
    required this.operacionId,
    required this.estadoId,
    this.datosIniciales,
    required this.estado,
    this.primaryColor = const Color(0xFF1B5E6B),
    required this.onGuardar,
  }) : super(key: key);
  
  @override
  State<DialogoFormularioPerforacion> createState() => _DialogoFormularioPerforacionState();
}

class _DialogoFormularioPerforacionState extends State<DialogoFormularioPerforacion> {
  bool isEditable = false;
  bool isLoading = true;

  // Controladores para cada taladro
  final TextEditingController nTaladrosProduccionController = TextEditingController();
  final TextEditingController metrosPerforadosProduccionController = TextEditingController();
  
  final TextEditingController nTaladrosRimadosController = TextEditingController();
  final TextEditingController metrosPerforadosRimadosController = TextEditingController();
  
  final TextEditingController nTaladrosAlivioController = TextEditingController();
  final TextEditingController metrosPerforadosAlivioController = TextEditingController();
  
  final TextEditingController nTaladrosRepasoController = TextEditingController();
  final TextEditingController metrosPerforadosRepasoController = TextEditingController();
  
  final TextEditingController numBarrasController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();

  // Variables para los campos seleccionables (NUEVO ORDEN)
  String? tipoLaborSeleccionado;    // 1º
  String? laborSeleccionado;         // 2º  
  String? alaSeleccionado;           // 3º
  String? nivelSeleccionado;         // 4º (antes era el primero)

  String? tipoPerforacionSeleccionado;
  String? longitudBarraSeleccionada;

  // Opciones para los dropdowns
  List<String> opcionesNivel = [];
  List<String> opcionesTipoLabor = [];
  List<String> opcionesLabor = [];
  List<String> opcionesAla = [];
  List<String> opcionesTipoPerforacion = [];
  List<String> opcionesLongitudBarras = [];

  // Listas filtradas para la selección en cascada (invertida)
  List<String> filteredTiposLabor = [];
  List<String> filteredLabores = [];
  List<String> filteredAlas = [];
  List<String> filteredNiveles = [];  // Nueva lista filtrada para niveles

  // Almacenar objetos completos
  List<PlanProduccion> planesProduccionCompletos = [];
  List<PlanMetraje> planesMetrajeCompletos = [];
  List<TipoPerforacion> tiposPerforacionCompletos = [];

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
        _cargarPlanesProduccionYMetraje(),
        _cargarTiposPerforacion(),
        _cargarLongitudBarras(),
      ]);
    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cargarLongitudBarras() async {
    try {
      final dbHelper = DatabaseHelper();
      final data = await dbHelper.getLongitudBarrasPorProceso(
        "PERFORACIÓN TALADROS LARGOS"
      );
      final lista = data
          .map((e) => e['longitud_pies'].toString())
          .toSet()
          .toList()
        ..sort((a, b) => double.parse(a).compareTo(double.parse(b)));
      setState(() {
        opcionesLongitudBarras = lista;
      });
    } catch (e) {
      print("Error cargando longitudes: $e");
    }
  }

  Future<void> _cargarPlanesProduccionYMetraje() async {
    try {
      final dbHelper = DatabaseHelper();
      final results = await Future.wait([
        dbHelper.getPlanesProduccion(),
        dbHelper.getPlanesMetraje(),
      ]);
      
      planesProduccionCompletos = results[0] as List<PlanProduccion>;
      planesMetrajeCompletos = results[1] as List<PlanMetraje>;

      Set<String> nivelesSet = {};
      Set<String> tiposLaborSet = {};
      Set<String> laboresSet = {};
      Set<String> alasSet = {};

      for (var plan in planesProduccionCompletos) {
        if (plan.nivel?.isNotEmpty ?? false) nivelesSet.add(plan.nivel!);
        if (plan.tipoLabor?.isNotEmpty ?? false) tiposLaborSet.add(plan.tipoLabor!);
        if (plan.labor?.isNotEmpty ?? false) laboresSet.add(plan.labor!);
        if (plan.ala?.isNotEmpty ?? false) alasSet.add(plan.ala!);
      }

      for (var plan in planesMetrajeCompletos) {
        if (plan.nivel?.isNotEmpty ?? false) nivelesSet.add(plan.nivel!);
        if (plan.tipoLabor?.isNotEmpty ?? false) tiposLaborSet.add(plan.tipoLabor!);
        if (plan.labor?.isNotEmpty ?? false) laboresSet.add(plan.labor!);
        if (plan.ala?.isNotEmpty ?? false) alasSet.add(plan.ala!);
      }

      setState(() {
        opcionesNivel = nivelesSet.toList()..sort();
        opcionesTipoLabor = tiposLaborSet.toList()..sort();
        opcionesLabor = laboresSet.toList()..sort();
        opcionesAla = alasSet.toList()..sort();
        filteredTiposLabor = List.from(opcionesTipoLabor);
        filteredLabores = List.from(opcionesLabor);
        filteredAlas = List.from(opcionesAla);
        filteredNiveles = List.from(opcionesNivel);
      });

    } catch (e) {
      print("Error cargando planes: $e");
      setState(() {
        opcionesNivel = ['Nivel 1', 'Nivel 2', 'Nivel 3', 'Nivel 4'];
        opcionesTipoLabor = ['Galería', 'Crucero', 'Rampa', 'Chimenea', 'Subterráneo'];
        opcionesLabor = ['Labor A', 'Labor B', 'Labor C', 'Labor D'];
        opcionesAla = ['Ala Norte', 'Ala Sur', 'Ala Este', 'Ala Oeste'];
        filteredTiposLabor = List.from(opcionesTipoLabor);
        filteredLabores = List.from(opcionesLabor);
        filteredAlas = List.from(opcionesAla);
        filteredNiveles = List.from(opcionesNivel);
      });
    }
  }

  Future<void> _cargarTiposPerforacion() async {
    try {
      final dbHelper = DatabaseHelper();
      tiposPerforacionCompletos = await dbHelper.getTiposPerforacionByProceso("PERFORACIÓN TALADROS LARGOS");
      final lista = tiposPerforacionCompletos
          .map((t) => t.nombre ?? '')
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      setState(() {
        opcionesTipoPerforacion = lista;
      });
    } catch (e) {
      print("Error cargando tipos perforación: $e");
      setState(() {
        opcionesTipoPerforacion = ['Perforación 1', 'Perforación 2', 'Perforación 3', 'Perforación 4'];
      });
    }
  }

  // NUEVAS FUNCIONES DE FILTRADO (orden invertido)
  void _onTipoLaborChanged(String? nuevoTipoLabor) {
    setState(() {
      tipoLaborSeleccionado = nuevoTipoLabor;
      laborSeleccionado = null;
      alaSeleccionado = null;
      nivelSeleccionado = null;
      _actualizarFiltros();
    });
  }

  void _onLaborChanged(String? nuevoLabor) {
    setState(() {
      laborSeleccionado = nuevoLabor;
      alaSeleccionado = null;
      nivelSeleccionado = null;
      _actualizarFiltros();
    });
  }

  void _onAlaChanged(String? nuevoAla) {
    setState(() {
      alaSeleccionado = nuevoAla;
      nivelSeleccionado = null;
      _actualizarFiltros();
    });
  }

void _actualizarFiltros() {

  // Filtrar Labores basado en Tipo Labor
  if (tipoLaborSeleccionado != null) {

    Set<String> laboresFiltrados = {};

    for (var plan in planesProduccionCompletos) {
      if (plan.tipoLabor == tipoLaborSeleccionado &&
          (plan.labor?.isNotEmpty ?? false)) {

        laboresFiltrados.add(plan.labor!);
      }
    }

    for (var plan in planesMetrajeCompletos) {
      if (plan.tipoLabor == tipoLaborSeleccionado &&
          (plan.labor?.isNotEmpty ?? false)) {

        laboresFiltrados.add(plan.labor!);
      }
    }

    filteredLabores = laboresFiltrados.toList()..sort();

  } else {

    filteredLabores = List.from(opcionesLabor);

  }

  // Filtrar Alas basado en Tipo Labor y Labor
  if (tipoLaborSeleccionado != null &&
      laborSeleccionado != null) {

    Set<String> alasFiltrados = {};

    for (var plan in planesProduccionCompletos) {
      if (plan.tipoLabor == tipoLaborSeleccionado &&
          plan.labor == laborSeleccionado &&
          (plan.ala?.isNotEmpty ?? false)) {

        alasFiltrados.add(plan.ala!);
      }
    }

    for (var plan in planesMetrajeCompletos) {
      if (plan.tipoLabor == tipoLaborSeleccionado &&
          plan.labor == laborSeleccionado &&
          (plan.ala?.isNotEmpty ?? false)) {

        alasFiltrados.add(plan.ala!);
      }
    }

    filteredAlas = alasFiltrados.toList()..sort();

  } else {

    filteredAlas = List.from(opcionesAla);

  }

  // Filtrar Niveles
  // Si hay ala -> filtra por ala
  // Si no hay ala -> solo por tipo labor + labor
  if (tipoLaborSeleccionado != null &&
      laborSeleccionado != null) {

    Set<String> nivelesFiltrados = {};

    for (var plan in planesProduccionCompletos) {

      bool coincideBase =
          plan.tipoLabor == tipoLaborSeleccionado &&
          plan.labor == laborSeleccionado;

      bool coincideAla =
          alaSeleccionado == null ||
          alaSeleccionado!.isEmpty ||
          plan.ala == alaSeleccionado;

      if (coincideBase &&
          coincideAla &&
          (plan.nivel?.isNotEmpty ?? false)) {

        nivelesFiltrados.add(plan.nivel!);
      }
    }

    for (var plan in planesMetrajeCompletos) {

      bool coincideBase =
          plan.tipoLabor == tipoLaborSeleccionado &&
          plan.labor == laborSeleccionado;

      bool coincideAla =
          alaSeleccionado == null ||
          alaSeleccionado!.isEmpty ||
          plan.ala == alaSeleccionado;

      if (coincideBase &&
          coincideAla &&
          (plan.nivel?.isNotEmpty ?? false)) {

        nivelesFiltrados.add(plan.nivel!);
      }
    }

    filteredNiveles = nivelesFiltrados.toList()..sort();

// Auto seleccionar nivel
if (filteredNiveles.isNotEmpty) {

  if (nivelSeleccionado == null ||
      !filteredNiveles.contains(nivelSeleccionado)) {

    nivelSeleccionado = filteredNiveles.first;
  }

} else {

  nivelSeleccionado = null;

}

  } else {

    filteredNiveles = List.from(opcionesNivel);

  }
}

  void _cargarDatosIniciales() {
    if (widget.datosIniciales != null) {
      setState(() {
        // Cargar en el nuevo orden
        tipoLaborSeleccionado = widget.datosIniciales!['tipo_labor']?.isNotEmpty == true 
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
        
        tipoPerforacionSeleccionado = widget.datosIniciales!['tipo_perforacion']?.isNotEmpty == true 
            ? widget.datosIniciales!['tipo_perforacion'] 
            : null;
        
        // Cargar nuevos campos
        nTaladrosProduccionController.text = widget.datosIniciales!['n_taladros_produccion'] ?? '';
        metrosPerforadosProduccionController.text = widget.datosIniciales!['metros_perforados_produccion'] ?? '';
        nTaladrosRimadosController.text = widget.datosIniciales!['n_taladros_rimados'] ?? '';
        metrosPerforadosRimadosController.text = widget.datosIniciales!['metros_perforados_rimados'] ?? '';
        nTaladrosAlivioController.text = widget.datosIniciales!['n_taladros_alivio'] ?? '';
        metrosPerforadosAlivioController.text = widget.datosIniciales!['metros_perforados_alivio'] ?? '';
        nTaladrosRepasoController.text = widget.datosIniciales!['n_taladros_repaso'] ?? '';
        metrosPerforadosRepasoController.text = widget.datosIniciales!['metros_perforados_repaso'] ?? '';
        
        longitudBarraSeleccionada = widget.datosIniciales!['long_barras']?.toString();
        numBarrasController.text = widget.datosIniciales!['num_barras'] ?? '';
        observacionesController.text = widget.datosIniciales!['observaciones'] ?? '';
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _actualizarFiltros();
      });
    }
  }

  Future<void> _guardarDatos() async {
    if (tipoPerforacionSeleccionado == null) {
      _mostrarSnackbar('Debe seleccionar un tipo de perforación', Colors.orange);
      return;
    }

    Map<String, dynamic> datosFormulario = {
      'tipo_labor': tipoLaborSeleccionado ?? '',  // Ahora primero
      'labor': laborSeleccionado ?? '',
      'ala': alaSeleccionado ?? '',
      'nivel': nivelSeleccionado ?? '',           // Ahora último
      
      // Nuevos campos para cada taladro
      'n_taladros_produccion': nTaladrosProduccionController.text,
      'metros_perforados_produccion': metrosPerforadosProduccionController.text,
      'n_taladros_rimados': nTaladrosRimadosController.text,
      'metros_perforados_rimados': metrosPerforadosRimadosController.text,
      'n_taladros_alivio': nTaladrosAlivioController.text,
      'metros_perforados_alivio': metrosPerforadosAlivioController.text,
      'n_taladros_repaso': nTaladrosRepasoController.text,
      'metros_perforados_repaso': metrosPerforadosRepasoController.text,
      
      'long_barras': longitudBarraSeleccionada ?? '',
      'num_barras': numBarrasController.text,
      'tipo_perforacion': tipoPerforacionSeleccionado ?? '',
      'tipo_perforacion_id': _obtenerIdTipoPerforacion(tipoPerforacionSeleccionado),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
                              _buildCompactDropdownField(
                                label: 'Tipo Labor',
                                value: tipoLaborSeleccionado,      // 1º
                                items: filteredTiposLabor,
                                onChanged: isEditable ? _onTipoLaborChanged : null,
                                icon: Icons.construction,
                              ),
                              const SizedBox(width: 8),
                              _buildCompactDropdownField(
                                label: 'Labor',
                                value: laborSeleccionado,          // 2º
                                items: filteredLabores,
                                onChanged: (tipoLaborSeleccionado != null && isEditable) 
                                    ? _onLaborChanged 
                                    : null,
                                icon: Icons.factory,
                              ),
                              const SizedBox(width: 8),
                              _buildCompactDropdownField(
                                label: 'Ala',
                                value: alaSeleccionado,           // 3º
                                items: filteredAlas,
                                onChanged: (laborSeleccionado != null && isEditable) 
                                    ? _onAlaChanged 
                                    : null,
                                icon: Icons.compare_arrows,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Taladro Producción
                          _buildSeccionTaladro(
                            titulo: 'Taladro Producción',
                            icon: Icons.golf_course,
                            nTaladrosController: nTaladrosProduccionController,
                            metrosController: metrosPerforadosProduccionController,
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
                                    ? (value) => setState(() => longitudBarraSeleccionada = value)
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
                                    ? (value) => setState(() => tipoPerforacionSeleccionado = value)
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
                color: color.withOpacity(0.1),
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
                color: widget.primaryColor.withOpacity(0.1),
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
                  color: widget.primaryColor.withOpacity(0.7),
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
                color: widget.primaryColor.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.15),
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
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
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
}
