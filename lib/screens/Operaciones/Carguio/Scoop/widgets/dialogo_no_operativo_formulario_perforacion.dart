import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/PlanMensual.dart';
import 'package:i_miner/models/PlanMetraje.dart';
import 'package:i_miner/models/PlanProduccion.dart';

class DialogoFormularioNoOpeCarguio extends StatefulWidget {
  final int operacionId;
  final int estadoId;
  final Map<String, dynamic>? datosIniciales;
  final String estado;
  final Color primaryColor;
  final Function(Map<String, dynamic>) onGuardar;

  const DialogoFormularioNoOpeCarguio({
    Key? key,
    required this.operacionId,
    required this.estadoId,
    this.datosIniciales,
    required this.estado,
    this.primaryColor = const Color(0xFF1B5E6B),
    required this.onGuardar,
  }) : super(key: key);
  
  @override
  State<DialogoFormularioNoOpeCarguio> createState() => _DialogoFormularioNoPerforacionState();
}

class _DialogoFormularioNoPerforacionState extends State<DialogoFormularioNoOpeCarguio> {
  bool isEditable = false;
  bool isLoading = true;
  bool isSmallScreen = false;

  // ✅ Controlador para observaciones
  final TextEditingController observacionesController = TextEditingController();

  // Variables para los campos seleccionables (NIVEL OCULTO)
  String? tipoLaborSeleccionado;
  String? laborSeleccionado;
  String? alaSeleccionado;
  String? nivelSeleccionado;  // ← OCULTO, se calcula automáticamente

  // Opciones para los dropdowns
  List<String> opcionesTipoLabor = [];
  List<String> opcionesLabor = [];
  List<String> opcionesAla = [];
  List<String> opcionesNivel = [];  // ← Interno, no visible

  // Listas filtradas para la selección en cascada
  List<String> filteredLabores = [];
  List<String> filteredAlas = [];
  List<String> filteredNiveles = [];  // ← Para filtrado interno

  // Almacenar objetos completos para referencia
  List<PlanMensual> planesMensualCompletos = [];
  List<PlanProduccion> planesProduccionCompletos = [];
  List<PlanMetraje> planesMetrajeCompletos = [];
  
  // Almacenar orígenes de SCOOPTRAM
  List<Map<String, dynamic>> origenesScooptram = [];
  
  // ✅ Variable para saber si el tipo labor seleccionado es un ORIGEN
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
      await _cargarPlanesCombinados();
    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ✅ Función para verificar si un tipo labor es un ORIGEN
  bool _esOrigen(String? tipoLabor) {
    if (tipoLabor == null) return false;
    return origenesScooptram.any((origen) => origen['nombre'] == tipoLabor);
  }

  // Cargar planes mensuales y construir opciones únicas
  Future<void> _cargarPlanesCombinados() async {
    try {
      final dbHelper = DatabaseHelper();
      
      // Cargar las tablas en paralelo
      final results = await Future.wait([
        dbHelper.getPlanesMensual(),
        dbHelper.getPlanesProduccion(),
        dbHelper.getPlanesMetraje(),
        dbHelper.getOrigenDestino('SCOOPTRAM', 'ORIGEN'),
      ]);
      
      planesMensualCompletos = results[0] as List<PlanMensual>;
      planesProduccionCompletos = results[1] as List<PlanProduccion>;
      planesMetrajeCompletos = results[2] as List<PlanMetraje>;
      origenesScooptram = results[3] as List<Map<String, dynamic>>;

      Set<String> tiposLaborSet = {};
      Set<String> laboresSet = {};
      Set<String> alasSet = {};
      Set<String> nivelesSet = {};

      // Procesar PlanMensual
      for (var plan in planesMensualCompletos) {
        if (plan.tipoLabor?.isNotEmpty ?? false) tiposLaborSet.add(plan.tipoLabor!);
        if (plan.labor?.isNotEmpty ?? false) laboresSet.add(plan.labor!);
        if (plan.ala?.isNotEmpty ?? false) alasSet.add(plan.ala!);
        if (plan.nivel?.isNotEmpty ?? false) nivelesSet.add(plan.nivel!);
      }

      // Procesar PlanProduccion
      for (var plan in planesProduccionCompletos) {
        if (plan.tipoLabor?.isNotEmpty ?? false) tiposLaborSet.add(plan.tipoLabor!);
        if (plan.labor?.isNotEmpty ?? false) laboresSet.add(plan.labor!);
        if (plan.ala?.isNotEmpty ?? false) alasSet.add(plan.ala!);
        if (plan.nivel?.isNotEmpty ?? false) nivelesSet.add(plan.nivel!);
      }

      // Procesar PlanMetraje
      for (var plan in planesMetrajeCompletos) {
        if (plan.tipoLabor?.isNotEmpty ?? false) tiposLaborSet.add(plan.tipoLabor!);
        if (plan.labor?.isNotEmpty ?? false) laboresSet.add(plan.labor!);
        if (plan.ala?.isNotEmpty ?? false) alasSet.add(plan.ala!);
        if (plan.nivel?.isNotEmpty ?? false) nivelesSet.add(plan.nivel!);
      }

      // ✅ Los orígenes de SCOOPTRAM van a "TIPO LABOR"
      for (var origen in origenesScooptram) {
        if (origen['nombre'] != null && origen['nombre'].toString().isNotEmpty) {
          tiposLaborSet.add(origen['nombre']);
        }
      }

      setState(() {
        opcionesTipoLabor = tiposLaborSet.toList()..sort();
        opcionesLabor = laboresSet.toList()..sort();
        opcionesAla = alasSet.toList()..sort();
        opcionesNivel = nivelesSet.toList()..sort();
        
        filteredLabores = List.from(opcionesLabor);
        filteredAlas = List.from(opcionesAla);
        filteredNiveles = List.from(opcionesNivel);
      });
    } catch (e) {
      print("Error cargando planes combinados: $e");
      setState(() {
        opcionesTipoLabor = ['Galería', 'Crucero', 'Rampa', 'Chimenea', 'Bodega', 'Pique'];
        opcionesLabor = ['Labor A', 'Labor B', 'Labor C', 'Labor D'];
        opcionesAla = ['Ala Norte', 'Ala Sur', 'Ala Este', 'Ala Oeste'];
        opcionesNivel = ['Nivel 1', 'Nivel 2', 'Nivel 3', 'Nivel 4'];
        
        filteredLabores = List.from(opcionesLabor);
        filteredAlas = List.from(opcionesAla);
        filteredNiveles = List.from(opcionesNivel);
      });
    }
  }

  // ✅ Actualizar filtros y auto-seleccionar nivel
  void _actualizarFiltros() {
    if (tipoLaborSeleccionado == null) {
      // No hay tipo labor seleccionado
      filteredLabores = List.from(opcionesLabor);
      filteredAlas = List.from(opcionesAla);
      laborSeleccionado = null;
      alaSeleccionado = null;
      nivelSeleccionado = null;
      isOrigenSeleccionado = false;
      return;
    }
    
    // Verificar si es un ORIGEN
    isOrigenSeleccionado = _esOrigen(tipoLaborSeleccionado);
    
    if (isOrigenSeleccionado) {
      // ✅ Es un ORIGEN: todo se limpia
      filteredLabores = [];
      filteredAlas = [];
      laborSeleccionado = null;
      alaSeleccionado = null;
      nivelSeleccionado = null;
      return;
    }
    
    // ✅ Es un TIPO LABOR normal (viene de planes)
    
    // Filtrar Labores basado en Tipo Labor
    Set<String> laboresFiltrados = {};
    
    for (var plan in planesMensualCompletos) {
      if (plan.tipoLabor == tipoLaborSeleccionado && 
          (plan.labor?.isNotEmpty ?? false)) {
        laboresFiltrados.add(plan.labor!);
      }
    }
    
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
    
    // Si no hay labores filtrados, limpiar labor
    if (filteredLabores.isEmpty) {
      laborSeleccionado = null;
    } else if (laborSeleccionado != null && 
               !filteredLabores.contains(laborSeleccionado)) {
      laborSeleccionado = null;
    }
    
    // Filtrar Alas basado en Tipo Labor y Labor
    if (laborSeleccionado != null) {
      Set<String> alasFiltrados = {};
      
      for (var plan in planesMensualCompletos) {
        if (plan.tipoLabor == tipoLaborSeleccionado && 
            plan.labor == laborSeleccionado && 
            (plan.ala?.isNotEmpty ?? false)) {
          alasFiltrados.add(plan.ala!);
        }
      }
      
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
      
      // Si no hay alas filtrados, limpiar ala
      if (filteredAlas.isEmpty) {
        alaSeleccionado = null;
      } else if (alaSeleccionado != null && 
                 !filteredAlas.contains(alaSeleccionado)) {
        alaSeleccionado = null;
      }
    } else {
      filteredAlas = List.from(opcionesAla);
      alaSeleccionado = null;
    }
    
    // ✅ AUTO-SELECCIONAR NIVEL (considerando si hay o no ala)
    if (tipoLaborSeleccionado != null && 
        laborSeleccionado != null &&
        !isOrigenSeleccionado) {
      
      Set<String> nivelesFiltrados = {};
      
      // Si hay ala seleccionada, filtrar por ala
      if (alaSeleccionado != null && alaSeleccionado!.isNotEmpty) {
        for (var plan in planesMensualCompletos) {
          if (plan.tipoLabor == tipoLaborSeleccionado && 
              plan.labor == laborSeleccionado && 
              plan.ala == alaSeleccionado && 
              (plan.nivel?.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel!);
          }
        }
        
        for (var plan in planesProduccionCompletos) {
          if (plan.tipoLabor == tipoLaborSeleccionado && 
              plan.labor == laborSeleccionado && 
              plan.ala == alaSeleccionado && 
              (plan.nivel?.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel!);
          }
        }
        
        for (var plan in planesMetrajeCompletos) {
          if (plan.tipoLabor == tipoLaborSeleccionado && 
              plan.labor == laborSeleccionado && 
              plan.ala == alaSeleccionado && 
              (plan.nivel?.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel!);
          }
        }
      } else {
        // ✅ SIN ALA: filtrar solo por tipo labor y labor
        for (var plan in planesMensualCompletos) {
          if (plan.tipoLabor == tipoLaborSeleccionado && 
              plan.labor == laborSeleccionado && 
              (plan.nivel?.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel!);
          }
        }
        
        for (var plan in planesProduccionCompletos) {
          if (plan.tipoLabor == tipoLaborSeleccionado && 
              plan.labor == laborSeleccionado && 
              (plan.nivel?.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel!);
          }
        }
        
        for (var plan in planesMetrajeCompletos) {
          if (plan.tipoLabor == tipoLaborSeleccionado && 
              plan.labor == laborSeleccionado && 
              (plan.nivel?.isNotEmpty ?? false)) {
            nivelesFiltrados.add(plan.nivel!);
          }
        }
      }
      
      // ✅ Auto-seleccionar el primer nivel
      if (nivelesFiltrados.isNotEmpty) {
        nivelSeleccionado = nivelesFiltrados.first;
      } else {
        nivelSeleccionado = null;
      }
    } else {
      // No tenemos los datos necesarios para determinar el nivel
      nivelSeleccionado = null;
    }
  }

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
      _actualizarFiltros();
    });
  }

  void _cargarDatosIniciales() {
    if (widget.datosIniciales != null) {
      setState(() {
        // Cargamos los datos guardados
        tipoLaborSeleccionado = widget.datosIniciales!['tipo_labor_inicio']?.isNotEmpty == true 
            ? widget.datosIniciales!['tipo_labor_inicio'] : null;
        laborSeleccionado = widget.datosIniciales!['labor_inicio']?.isNotEmpty == true 
            ? widget.datosIniciales!['labor_inicio'] : null;
        alaSeleccionado = widget.datosIniciales!['ala_inicio']?.isNotEmpty == true 
            ? widget.datosIniciales!['ala_inicio'] : null;
        nivelSeleccionado = widget.datosIniciales!['nivel_inicio']?.isNotEmpty == true 
            ? widget.datosIniciales!['nivel_inicio'] : null;
        observacionesController.text = widget.datosIniciales!['observaciones'] ?? '';
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _actualizarFiltros();
      });
    }
  }

  Future<void> _guardarDatos() async {
    Map<String, dynamic> datosFormulario = {
      // ✅ Guardamos el nivel calculado automáticamente
      'nivel_inicio': nivelSeleccionado ?? '',
      'tipo_labor_inicio': tipoLaborSeleccionado ?? '',
      'labor_inicio': laborSeleccionado ?? '',
      'ala_inicio': alaSeleccionado ?? '',
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
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    isSmallScreen = screenWidth < 600;
    
    final dialogWidth = isSmallScreen 
        ? screenWidth * 0.95
        : 800.0;
    
    final dialogHeight = isSmallScreen
        ? MediaQuery.of(context).size.height * 0.85
        : MediaQuery.of(context).size.height * 0.7;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: dialogHeight,
          maxWidth: 800,
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
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSeccionUbicacion(),  // ← Sin el campo Nivel visible
                          const SizedBox(height: 20),
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

  Widget _buildSeccionUbicacion() {
    if (isSmallScreen) {
      // Versión para móvil: dropdowns apilados verticalmente (SIN NIVEL)
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
                child: Icon(
                  Icons.location_on,
                  size: 14,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Ubicación',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
              if (isOrigenSeleccionado) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    'ORIGEN',
                    style: TextStyle(fontSize: 9, color: Colors.purple.shade700, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ✅ TIPO LABOR es el principal ahora
          _buildCompactDropdownField(
            label: 'Tipo Labor / Origen',
            value: tipoLaborSeleccionado,
            items: opcionesTipoLabor,
            onChanged: isEditable ? _onTipoLaborChanged : null,
            icon: Icons.construction,
          ),
          if (!isOrigenSeleccionado) ...[
            const SizedBox(height: 12),
            _buildCompactDropdownField(
              label: 'Labor',
              value: laborSeleccionado,
              items: filteredLabores,
              onChanged: (tipoLaborSeleccionado != null && isEditable) 
                  ? _onLaborChanged : null,
              icon: Icons.factory,
            ),
            const SizedBox(height: 12),
            _buildCompactDropdownField(
              label: 'Ala (Opcional)',
              value: alaSeleccionado,
              items: filteredAlas,
              onChanged: (laborSeleccionado != null && isEditable) 
                  ? _onAlaChanged : null,
              icon: Icons.compare_arrows,
              isOptional: true,
            ),
          ],
          // ❌ EL CAMPO NIVEL NO SE MUESTRA (está oculto)
        ],
      );
    } else {
      // Versión para PC: dropdowns horizontales en fila (SIN NIVEL)
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
                child: Icon(
                  Icons.location_on,
                  size: 14,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Ubicación',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
              if (isOrigenSeleccionado) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    'ORIGEN',
                    style: TextStyle(fontSize: 9, color: Colors.purple.shade700, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactDropdownField(
                  label: 'Tipo Labor / Origen',
                  value: tipoLaborSeleccionado,
                  items: opcionesTipoLabor,
                  onChanged: isEditable ? _onTipoLaborChanged : null,
                  icon: Icons.construction,
                ),
              ),
              if (!isOrigenSeleccionado) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactDropdownField(
                    label: 'Labor',
                    value: laborSeleccionado,
                    items: filteredLabores,
                    onChanged: (tipoLaborSeleccionado != null && isEditable) 
                        ? _onLaborChanged : null,
                    icon: Icons.factory,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactDropdownField(
                    label: 'Ala (Opcional)',
                    value: alaSeleccionado,
                    items: filteredAlas,
                    onChanged: (laborSeleccionado != null && isEditable) 
                        ? _onAlaChanged : null,
                    icon: Icons.compare_arrows,
                    isOptional: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }
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
              child: Icon(
                Icons.note_alt,
                size: 14,
                color: widget.primaryColor,
              ),
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
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: isSmallScreen ? 120 : 100,
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
              hintStyle: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.comment,
                  size: isSmallScreen ? 16 : 18,
                  color: widget.primaryColor.withOpacity(0.7),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              alignLabelWithHint: true,
            ),
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: 12),
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
            child: Icon(
              Icons.description,
              color: Colors.white,
              size: isSmallScreen ? 16 : 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSmallScreen ? 'Formulario No Operativo' : 'Formulario de Perforación no operativa',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 13 : 16,
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
        color: isEditable ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEditable ? Colors.green : Colors.grey, width: 0.5),
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
    bool isOptional = false,
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
              Icon(icon, size: isSmallScreen ? 12 : 14, color: widget.primaryColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  items.isEmpty ? (isOrigenSeleccionado ? 'No aplica para Origen' : 'Cargando...') : label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, size: isSmallScreen ? 16 : 18, color: widget.primaryColor),
          style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.black87),
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
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
          onChanged: isEnabled ? (newValue) {
            // Permitir seleccionar null para campos opcionales
            onChanged?.call(newValue);
          } : null,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}