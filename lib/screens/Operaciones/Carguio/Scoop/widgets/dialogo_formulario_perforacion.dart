import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/PlanMensual.dart';
import 'package:i_miner/models/PlanProduccion.dart';

class DialogoFormularioPerforacion extends StatefulWidget {
  final int operacionId;
  final int estadoId;
  final Map<String, dynamic>? datosIniciales;
  final String estado;
  final Color primaryColor;
  final Function(Map<String, dynamic>) onGuardar;

  const DialogoFormularioPerforacion({
    super.key,
    required this.operacionId,
    required this.estadoId,
    this.datosIniciales,
    required this.estado,
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
  bool isSmallScreen = false;

  // Controlador para observaciones
  final TextEditingController observacionesController = TextEditingController();

  // Variables para INICIO
  String? tipoLaborInicioSeleccionado;
  String? laborInicioSeleccionado;
  String? alaInicioSeleccionado;
  String? nivelInicioSeleccionado; // ← OCULTO, se calcula automáticamente

  // Variable para DESTINO
  String? ubicacionDestinoSeleccionado;
  int? ubicacionDestinoId;

  // Número de cucharas
  final TextEditingController nCucharasController = TextEditingController();

  // Opciones para los dropdowns
  List<String> opcionesTipoLabor = [];
  List<String> opcionesLabor = [];
  List<String> opcionesAla = [];
  List<String> opcionesNivel = [];

  // Opciones para ubicación destino
  List<Map<String, dynamic>> destinosDisponibles = [];
  List<String> opcionesUbicacionDestino = [];

  // Listas filtradas
  List<String> filteredLaboresInicio = [];
  List<String> filteredAlasInicio = [];

  // Almacenar objetos completos
  List<PlanMensual> planesMensualCompletos = [];
  List<PlanProduccion> planesProduccionCompletos = [];

  // Almacenar orígenes de SCOOPTRAM
  List<Map<String, dynamic>> origenesScooptram = [];

  // ✅ Variable para saber si el tipo labor seleccionado es un ORIGEN o un PLAN
  bool isOrigenSeleccionado = false;

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
      await Future.wait([_cargarDestinosSCOOPTRAM()]);
    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cargarDestinosSCOOPTRAM() async {
    try {
      final dbHelper = DatabaseHelper();
      destinosDisponibles = await dbHelper.getOrigenDestino(
        'SCOOPTRAM',
        'DESTINO',
      );
      setState(() {
        opcionesUbicacionDestino = destinosDisponibles
            .map((destino) => destino['nombre'] as String)
            .toList();
      });
    } catch (e) {
      print("Error cargando destinos: $e");
      setState(() => opcionesUbicacionDestino = []);
    }
  }

  Future<void> _cargarPlanesCombinados() async {
    try {
      final dbHelper = DatabaseHelper();

      final results = await Future.wait([
        dbHelper.getOrigenDestino('SCOOPTRAM', 'ORIGEN'),
      ]);

      origenesScooptram = results[0];

      Set<String> tiposLaborSet = {};
      Set<String> laboresSet = {};
      Set<String> alasSet = {};
      Set<String> nivelesSet = {};

      // Agregar datos de PlanMensual
      for (var plan in planesMensualCompletos) {
        if (plan.tipoLabor.isNotEmpty ?? false) {
          tiposLaborSet.add(plan.tipoLabor);
        }
        if (plan.labor.isNotEmpty ?? false) laboresSet.add(plan.labor);
        if (plan.ala.isNotEmpty ?? false) alasSet.add(plan.ala);
        if (plan.nivel.isNotEmpty ?? false) nivelesSet.add(plan.nivel);
      }

      // Agregar datos de PlanProduccion
      for (var plan in planesProduccionCompletos) {
        if (plan.tipoLabor.isNotEmpty ?? false) {
          tiposLaborSet.add(plan.tipoLabor);
        }
        if (plan.labor.isNotEmpty ?? false) laboresSet.add(plan.labor);
        if (plan.ala?.isNotEmpty ?? false) alasSet.add(plan.ala!);
        if (plan.nivel?.isNotEmpty ?? false) nivelesSet.add(plan.nivel!);
      }

      // ✅ Los orígenes de SCOOPTRAM van a "TIPO LABOR"
      for (var origen in origenesScooptram) {
        if (origen['nombre'] != null &&
            origen['nombre'].toString().isNotEmpty) {
          tiposLaborSet.add(origen['nombre']);
        }
      }

      setState(() {
        opcionesTipoLabor = tiposLaborSet.toList()..sort();
        opcionesLabor = laboresSet.toList()..sort();
        opcionesAla = alasSet.toList()..sort();
        opcionesNivel = nivelesSet.toList()..sort();

        filteredLaboresInicio = List.from(opcionesLabor);
        filteredAlasInicio = List.from(opcionesAla);
      });
    } catch (e) {
      print("Error cargando planes: $e");
      setState(() {
        opcionesTipoLabor = [
          'Galería',
          'Crucero',
          'Rampa',
          'Chimenea',
          'Bodega',
          'Pique',
        ];
        opcionesLabor = ['Labor 01', 'Labor 02', 'Labor 03', 'Labor 04'];
        opcionesAla = ['Ala Norte', 'Ala Sur', 'Ala Este', 'Ala Oeste'];
        opcionesNivel = ['Nv 300', 'Nv 320', 'Nv 340', 'Nv 360'];

        filteredLaboresInicio = List.from(opcionesLabor);
        filteredAlasInicio = List.from(opcionesAla);
      });
    }
  }

  // ✅ Función para verificar si un tipo labor es un ORIGEN o viene de PLANES
  bool _esOrigen(String? tipoLabor) {
    if (tipoLabor == null) return false;
    return origenesScooptram.any((origen) => origen['nombre'] == tipoLabor);
  }

  // ✅ Actualizar filtros basado en TIPO LABOR
  void _actualizarFiltros() {
    if (tipoLaborInicioSeleccionado == null) {
      // No hay tipo labor seleccionado
      filteredLaboresInicio = List.from(opcionesLabor);
      filteredAlasInicio = List.from(opcionesAla);
      laborInicioSeleccionado = null;
      alaInicioSeleccionado = null;
      nivelInicioSeleccionado = null;
      isOrigenSeleccionado = false;
      return;
    }

    // Verificar si es un ORIGEN
    isOrigenSeleccionado = _esOrigen(tipoLaborInicioSeleccionado);

    if (isOrigenSeleccionado) {
      // ✅ Es un ORIGEN: todo se limpia
      filteredLaboresInicio = [];
      filteredAlasInicio = [];
      laborInicioSeleccionado = null;
      alaInicioSeleccionado = null;
      nivelInicioSeleccionado = null;
      return;
    }

    // ✅ Es un TIPO LABOR normal (viene de planes)

    // Filtrar Labores
    Set<String> laboresFiltrados = {};

    for (var plan in planesMensualCompletos) {
      if (plan.tipoLabor == tipoLaborInicioSeleccionado &&
          (plan.labor.isNotEmpty ?? false)) {
        laboresFiltrados.add(plan.labor);
      }
    }

    for (var plan in planesProduccionCompletos) {
      if (plan.tipoLabor == tipoLaborInicioSeleccionado &&
          (plan.labor.isNotEmpty ?? false)) {
        laboresFiltrados.add(plan.labor);
      }
    }

    filteredLaboresInicio = laboresFiltrados.toList()..sort();

    // Si no hay labores filtrados, limpiar labor
    if (filteredLaboresInicio.isEmpty) {
      laborInicioSeleccionado = null;
    } else if (laborInicioSeleccionado != null &&
        !filteredLaboresInicio.contains(laborInicioSeleccionado)) {
      laborInicioSeleccionado = null;
    }

    // ✅ Filtrar Alas (solo si hay labor seleccionada)
    if (laborInicioSeleccionado != null) {
      Set<String> alasFiltrados = {};

      for (var plan in planesMensualCompletos) {
        if (plan.tipoLabor == tipoLaborInicioSeleccionado &&
            plan.labor == laborInicioSeleccionado &&
            (plan.ala.isNotEmpty ?? false)) {
          alasFiltrados.add(plan.ala);
        }
      }

      for (var plan in planesProduccionCompletos) {
        if (plan.tipoLabor == tipoLaborInicioSeleccionado &&
            plan.labor == laborInicioSeleccionado &&
            (plan.ala?.isNotEmpty ?? false)) {
          alasFiltrados.add(plan.ala!);
        }
      }

      filteredAlasInicio = alasFiltrados.toList()..sort();

      // Si no hay alas filtrados, limpiar ala
      if (filteredAlasInicio.isEmpty) {
        alaInicioSeleccionado = null;
      } else if (alaInicioSeleccionado != null &&
          !filteredAlasInicio.contains(alaInicioSeleccionado)) {
        alaInicioSeleccionado = null;
      }
    } else {
      filteredAlasInicio = List.from(opcionesAla);
      alaInicioSeleccionado = null;
    }

    // ✅ AUTO-SELECCIONAR NIVEL (considerando si hay o no ala)
    if (tipoLaborInicioSeleccionado != null &&
        laborInicioSeleccionado != null &&
        !isOrigenSeleccionado) {
      Set<String> nivelesFiltrados = {};

      // Si hay ala seleccionada, filtrar por ala
      if (alaInicioSeleccionado != null && alaInicioSeleccionado!.isNotEmpty) {
        for (var plan in planesMensualCompletos) {
          if (plan.tipoLabor == tipoLaborInicioSeleccionado &&
              plan.labor == laborInicioSeleccionado &&
              plan.ala == alaInicioSeleccionado &&
              (plan.nivel.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel);
          }
        }

        for (var plan in planesProduccionCompletos) {
          if (plan.tipoLabor == tipoLaborInicioSeleccionado &&
              plan.labor == laborInicioSeleccionado &&
              plan.ala == alaInicioSeleccionado &&
              (plan.nivel?.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel!);
          }
        }
      } else {
        // ✅ SIN ALA: filtrar solo por tipo labor y labor
        for (var plan in planesMensualCompletos) {
          if (plan.tipoLabor == tipoLaborInicioSeleccionado &&
              plan.labor == laborInicioSeleccionado &&
              (plan.nivel.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel);
          }
        }

        for (var plan in planesProduccionCompletos) {
          if (plan.tipoLabor == tipoLaborInicioSeleccionado &&
              plan.labor == laborInicioSeleccionado &&
              (plan.nivel?.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel!);
          }
        }
      }

      // ✅ Auto-seleccionar el primer nivel
      if (nivelesFiltrados.isNotEmpty) {
        nivelInicioSeleccionado = nivelesFiltrados.first;
      } else {
        nivelInicioSeleccionado = null;
      }
    } else {
      // No tenemos los datos necesarios para determinar el nivel
      nivelInicioSeleccionado = null;
    }
  }

  void _cargarDatosIniciales() {
    if (widget.datosIniciales != null) {
      setState(() {
        tipoLaborInicioSeleccionado =
            widget.datosIniciales!['tipo_labor_inicio']?.isNotEmpty == true
            ? widget.datosIniciales!['tipo_labor_inicio']
            : null;
        laborInicioSeleccionado =
            widget.datosIniciales!['labor_inicio']?.isNotEmpty == true
            ? widget.datosIniciales!['labor_inicio']
            : null;
        alaInicioSeleccionado =
            widget.datosIniciales!['ala_inicio']?.isNotEmpty == true
            ? widget.datosIniciales!['ala_inicio']
            : null;
        nivelInicioSeleccionado =
            widget.datosIniciales!['nivel_inicio']?.isNotEmpty == true
            ? widget.datosIniciales!['nivel_inicio']
            : null;

        ubicacionDestinoId = widget.datosIniciales!['ubicacion_destino_id'];
        ubicacionDestinoSeleccionado =
            widget.datosIniciales!['ubicacion_destino'];
        nCucharasController.text =
            widget.datosIniciales!['n_cucharas']?.toString() ?? '0';
        observacionesController.text =
            widget.datosIniciales!['observaciones'] ?? '';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _actualizarFiltros();
      });
    }
  }

  Future<void> _guardarDatos() async {
    int? destinoId;
    if (ubicacionDestinoSeleccionado != null) {
      final destinoEncontrado = destinosDisponibles.firstWhere(
        (destino) => destino['nombre'] == ubicacionDestinoSeleccionado,
        orElse: () => {},
      );
      destinoId = destinoEncontrado['id'];
    }

    Map<String, dynamic> datosFormulario = {
      'nivel_inicio': nivelInicioSeleccionado ?? '',
      'tipo_labor_inicio': tipoLaborInicioSeleccionado ?? '',
      'labor_inicio': laborInicioSeleccionado ?? '',
      'ala_inicio': alaInicioSeleccionado ?? '',
      'ubicacion_destino_id': destinoId ?? 0,
      'ubicacion_destino': ubicacionDestinoSeleccionado ?? '',
      'n_cucharas': int.tryParse(nCucharasController.text) ?? 0,
      'observaciones': observacionesController.text,
    };

    widget.onGuardar(datosFormulario);
    _mostrarSnackbar('Formulario guardado correctamente', Colors.green);
    Navigator.pop(context);
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
    nCucharasController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    isSmallScreen = screenWidth < 600;

    final dialogWidth = isSmallScreen ? screenWidth * 0.95 : 1000.0;

    final dialogHeight = isSmallScreen
        ? MediaQuery.of(context).size.height * 0.9
        : 700.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxWidth: 1000, maxHeight: dialogHeight),
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
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSeccionUbicacionInicio(),
                          const SizedBox(height: 16),
                          _buildSeccionUbicacionDestino(),
                          const SizedBox(height: 16),
                          _buildSeccionCucharas(),
                          const SizedBox(height: 16),
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

  Widget _buildSeccionUbicacionInicio() {
    Widget dropdownField = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  size: 14,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ubicación INICIO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              if (isOrigenSeleccionado) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    'ORIGEN',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (isSmallScreen) ...[
            _buildCompactDropdownField(
              label: 'Tipo Labor / Origen',
              value: tipoLaborInicioSeleccionado,
              items: opcionesTipoLabor,
              onChanged: isEditable
                  ? (value) {
                      setState(() {
                        tipoLaborInicioSeleccionado = value;
                        laborInicioSeleccionado = null;
                        alaInicioSeleccionado = null;
                        nivelInicioSeleccionado = null;
                        _actualizarFiltros();
                      });
                    }
                  : null,
              icon: Icons.construction,
            ),
            const SizedBox(height: 8),
            if (!isOrigenSeleccionado) ...[
              _buildCompactDropdownField(
                label: 'Labor',
                value: laborInicioSeleccionado,
                items: filteredLaboresInicio,
                onChanged:
                    (tipoLaborInicioSeleccionado != null &&
                        isEditable &&
                        !isOrigenSeleccionado)
                    ? (value) {
                        setState(() {
                          laborInicioSeleccionado = value;
                          alaInicioSeleccionado = null;
                          nivelInicioSeleccionado = null;
                          _actualizarFiltros();
                        });
                      }
                    : null,
                icon: Icons.factory,
              ),
              const SizedBox(height: 8),
              // ✅ Campo ALA (opcional) - se muestra siempre, pero puede estar vacío
              _buildCompactDropdownField(
                label: 'Ala (Opcional)',
                value: alaInicioSeleccionado,
                items: filteredAlasInicio,
                onChanged:
                    (laborInicioSeleccionado != null &&
                        isEditable &&
                        !isOrigenSeleccionado)
                    ? (value) {
                        setState(() {
                          alaInicioSeleccionado = value;
                          _actualizarFiltros();
                        });
                      }
                    : null,
                icon: Icons.compare_arrows,
                isOptional: true, // ← Nuevo parámetro opcional
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildCompactDropdownField(
                    label: 'Tipo Labor / Origen',
                    value: tipoLaborInicioSeleccionado,
                    items: opcionesTipoLabor,
                    onChanged: isEditable
                        ? (value) {
                            setState(() {
                              tipoLaborInicioSeleccionado = value;
                              laborInicioSeleccionado = null;
                              alaInicioSeleccionado = null;
                              nivelInicioSeleccionado = null;
                              _actualizarFiltros();
                            });
                          }
                        : null,
                    icon: Icons.construction,
                  ),
                ),
                if (!isOrigenSeleccionado) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactDropdownField(
                      label: 'Labor',
                      value: laborInicioSeleccionado,
                      items: filteredLaboresInicio,
                      onChanged:
                          (tipoLaborInicioSeleccionado != null && isEditable)
                          ? (value) {
                              setState(() {
                                laborInicioSeleccionado = value;
                                alaInicioSeleccionado = null;
                                nivelInicioSeleccionado = null;
                                _actualizarFiltros();
                              });
                            }
                          : null,
                      icon: Icons.factory,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactDropdownField(
                      label: 'Ala (Opcional)',
                      value: alaInicioSeleccionado,
                      items: filteredAlasInicio,
                      onChanged: (laborInicioSeleccionado != null && isEditable)
                          ? (value) {
                              setState(() {
                                alaInicioSeleccionado = value;
                                _actualizarFiltros();
                              });
                            }
                          : null,
                      icon: Icons.compare_arrows,
                      isOptional: true,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    return dropdownField;
  }

  Widget _buildSeccionUbicacionDestino() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ubicación DESTINO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'SCOOPTRAM',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCompactDropdownField(
            label: 'Seleccionar destino',
            value: ubicacionDestinoSeleccionado,
            items: opcionesUbicacionDestino,
            onChanged: isEditable
                ? (value) =>
                      setState(() => ubicacionDestinoSeleccionado = value)
                : null,
            icon: Icons.flag,
          ),
          if (opcionesUbicacionDestino.isEmpty && !isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No hay destinos disponibles',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeccionCucharas() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.calculate,
                  size: 14,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'N° Cucharas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nCucharasController,
            enabled: isEditable,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ingrese número',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionObservaciones() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, size: 16, color: widget.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Observaciones',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: observacionesController,
            enabled: isEditable,
            maxLines: isSmallScreen ? 4 : 3,
            decoration: InputDecoration(
              hintText: 'Escriba observaciones adicionales...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.all(10),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 12,
      ),
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
            child: Icon(
              Icons.description,
              color: Colors.white,
              size: isSmallScreen ? 16 : 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSmallScreen ? 'SCOOPTRAM' : 'Formulario SCOOPTRAM',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
              fontSize: isSmallScreen ? 8 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
    required IconData icon,
    bool isOptional = false, // ← Nuevo parámetro
  }) {
    bool valueExists = value != null && items.contains(value);
    bool isEnabled = onChanged != null && isEditable;

    // Para campos opcionales, permitir valor null explícitamente
    final displayValue = valueExists ? value : null;

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
          value: displayValue,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSmallScreen ? 12 : 14,
                color: widget.primaryColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  items.isEmpty
                      ? (isOrigenSeleccionado
                            ? 'No aplica para Origen'
                            : 'Cargando...')
                      : label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
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
            size: isSmallScreen ? 16 : 18,
            color: widget.primaryColor,
          ),
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 12,
            color: Colors.black87,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(6),
          items: [
            // ✅ Agregar opción "Ninguno" para campos opcionales
            if (isOptional)
              DropdownMenuItem<String>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.clear, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Ninguno',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ...items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: isEnabled
              ? (newValue) {
                  // Permitir seleccionar null para campos opcionales
                  onChanged.call(newValue);
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 10,
      ),
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
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: isSmallScreen ? 12 : 13,
              ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save, size: isSmallScreen ? 12 : 14),
                  const SizedBox(width: 6),
                  Text(
                    'Guardar',
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
}
