import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/offline_authorization_repository.dart';
import 'package:i_miner/core/network/connection_provider.dart';
import 'package:i_miner/screens/Dash/actualizacion_dialog.dart';
import 'package:i_miner/screens/Envio%20a%20nube/operaciones_centralizada.dart';
import 'package:i_miner/screens/Operaciones/lista_perforacion_screen.dart';
import 'package:i_miner/screens/Operaciones/Mediciones/select_tipo_explosivo.dart';
import 'package:i_miner/screens/Operaciones/Servicio%20Auxiliares/ServiciosAuxiliaresScreen.dart';
import 'package:i_miner/screens/widgets/ReportButton.dart';
import 'package:i_miner/screens/login/login_screen.dart';
import 'package:i_miner/screens/widgets/dialogo_confirmar_cierre.dart';
import 'package:i_miner/screens/widgets/botones_estado.dart';
import 'package:i_miner/screens/widgets/tabla_operaciones.dart';
import 'package:i_miner/screens/widgets/show_registro_operacion.dart';
import 'package:i_miner/screens/widgets/dialogo_condiciones_equipo.dart';
import 'package:i_miner/screens/widgets/dialogo_formulario_no_operativo.dart';
import 'package:i_miner/screens/widgets/botones_acciones_inferiores.dart';
import 'package:i_miner/screens/widgets/dialog_check_imagen.dart';

// Tal largo widgets
import 'package:i_miner/screens/Operaciones/Tal%20largo/widgets/dialogo_formulario_perforacion.dart'
    as tl;

// Tal horizontal widgets
import 'package:i_miner/screens/Operaciones/Tal%20horizontal/widgets/dialogo_formulario_perforacion.dart'
    as th;

// Sostenimiento widgets
import 'package:i_miner/screens/Operaciones/sostenimiento/widgets/dialogo_formulario_perforacion.dart'
    as so;

import 'package:i_miner/screens/Operaciones/Acarreo/Dumper/widgets/dialogo_formulario_perforacion.dart'
    as ad;

import 'package:i_miner/screens/Operaciones/Carguio/Scoop/widgets/dialogo_formulario_perforacion.dart'
    as cs;

import 'package:i_miner/shared/widgets/registro_operacion_dialog.dart';
import 'package:i_miner/services/get%20nube/actualizacion_service.dart';
import 'package:provider/provider.dart';
import 'package:i_miner/services/get%20nube/registros%20nube/ApiServiceExploracion.dart';

class _DashboardModuleDefinition {
  const _DashboardModuleDefinition({
    required this.legacyKey,
    required this.title,
    required this.image,
    required this.authorizedNames,
    this.processLookupNames = const [],
    this.authorizedProcessIds = const {},
  });

  final String legacyKey;
  final String title;
  final String image;
  final Set<String> authorizedNames;
  final List<String> processLookupNames;
  final Set<int> authorizedProcessIds;
}

final List<_DashboardModuleDefinition> _dashboardModuleDefinitions = [
  _DashboardModuleDefinition(
    legacyKey: 'PERFORACIÓN TALADROS LARGOS',
    title: 'PERFORACIÓN\nTALADROS LARGOS',
    image: 'assets/images/perforacion_taladros.png',
    processLookupNames: [
      'PERFORACIÓN TALADROS LARGOS',
      'TALADRO LARGO',
      'TALADROS LARGOS',
    ],
    authorizedProcessIds: {1},
    authorizedNames: {
      normalizeAuthorizationName('PERFORACIÓN TALADROS LARGOS'),
      normalizeAuthorizationName('TALADRO LARGO'),
      normalizeAuthorizationName('TALADROS LARGOS'),
    },
  ),
  _DashboardModuleDefinition(
    legacyKey: 'PERFORACIÓN HORIZONTAL',
    title: 'PERFORACIÓN\nHORIZONTAL',
    image: 'assets/images/perfo_horizontal.png',
    processLookupNames: [
      'PERFORACIÓN HORIZONTAL',
      'TALADRO HORIZONTAL',
      'TALADROS HORIZONTAL',
    ],
    authorizedProcessIds: {2},
    authorizedNames: {
      normalizeAuthorizationName('PERFORACIÓN HORIZONTAL'),
      normalizeAuthorizationName('TALADRO HORIZONTAL'),
      normalizeAuthorizationName('TALADROS HORIZONTAL'),
      normalizeAuthorizationName('Taladro Horizontal'),
    },
  ),
  _DashboardModuleDefinition(
    legacyKey: 'SOSTENIMIENTO',
    title: 'SOSTENIMIENTO',
    image: 'assets/images/sostenimiento.png',
    processLookupNames: ['SOSTENIMIENTO', 'EMPERNADOR'],
    authorizedProcessIds: {3},
    authorizedNames: {
      normalizeAuthorizationName('SOSTENIMIENTO'),
      normalizeAuthorizationName('EMPERNADOR'),
    },
  ),
  _DashboardModuleDefinition(
    legacyKey: 'SERVICIOS AUXILIARES',
    title: 'SERVICIOS\nAUXILIARES',
    image: 'assets/images/servicio_auxiliares.png',
    authorizedProcessIds: {7, 8, 9},
    authorizedNames: {
      normalizeAuthorizationName('SERVICIOS AUXILIARES'),
      normalizeAuthorizationName('SERVICIO AUXILIARES'),
      normalizeAuthorizationName('ANFO CHANGER'),
      normalizeAuthorizationName('ANFOCHARGER'),
      normalizeAuthorizationName('SCISSOR'),
      normalizeAuthorizationName('SCALAMISTA'),
      normalizeAuthorizationName('SCALAMIN'),
    },
  ),
  _DashboardModuleDefinition(
    legacyKey: 'ACEROS DE PERFORACIÓN',
    title: 'ACEROS DE\nPERFORACIÓN',
    image: 'assets/images/aceros_de_perforacion.png',
    authorizedNames: {
      normalizeAuthorizationName('ACEROS DE PERFORACIÓN'),
      normalizeAuthorizationName('ACEROS DE PERFORACION'),
    },
  ),
  _DashboardModuleDefinition(
    legacyKey: 'CARGUÍO',
    title: 'CARGUÍO',
    image: 'assets/images/carguio.png',
    processLookupNames: ['SCOOP', 'CARGUÍO', 'CARGUIO', 'SCOOPTRAM'],
    authorizedProcessIds: {4},
    authorizedNames: {
      normalizeAuthorizationName('CARGUÍO'),
      normalizeAuthorizationName('CARGUIO'),
      normalizeAuthorizationName('SCOOP'),
    },
  ),
  _DashboardModuleDefinition(
    legacyKey: 'ACARREO',
    title: 'ACARREO',
    image: 'assets/images/acarreo.png',
    processLookupNames: ['ACARREO', 'DUMPER'],
    authorizedProcessIds: {5},
    authorizedNames: {
      normalizeAuthorizationName('ACARREO'),
      normalizeAuthorizationName('DUMPER'),
    },
  ),
  _DashboardModuleDefinition(
    legacyKey: 'MEDICIONES',
    title: 'MEDICIONES',
    image: 'assets/images/medicion.png',
    authorizedNames: {
      normalizeAuthorizationName('MEDICIONES'),
      normalizeAuthorizationName('MEDICIONES TAL. HORIZONTAL'),
      normalizeAuthorizationName('MEDICIONES TAL. LARGO'),
    },
  ),
];

Future<Map<String, bool>> loadDashboardAuthorizationState({
  required String dni,
  DatabaseHelper? databaseHelper,
  OfflineAuthorizationRepository? authorizationRepository,
  Map<String, dynamic>? cachedUser,
}) async {
  final dbHelper = databaseHelper ?? DatabaseHelper();
  final repository =
      authorizationRepository ?? OfflineAuthorizationRepository();

  if (!await repository.hasNormalizedProcessAuth(dni)) {
    return {
      for (final module in _dashboardModuleDefinitions) module.legacyKey: false,
    };
  }

  final authorizedProcesses = await repository.getAuthorizedProcesses(dni);
  final authorizedProcessIds = authorizedProcesses
      .map((process) => process.id)
      .toSet();
  final normalizedProcesses = authorizedProcesses
      .map((process) => normalizeAuthorizationName(process.name))
      .toSet();

  return {
    for (final module in _dashboardModuleDefinitions)
      module.legacyKey:
          module.authorizedProcessIds.any(authorizedProcessIds.contains) ||
          module.authorizedNames.any(normalizedProcesses.contains),
  };
}

class DashboardScreen extends StatefulWidget {
  final String dni;
  final String token;

  const DashboardScreen({super.key, required this.dni, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color navbarColor = const Color(
    0xFF1B5E6B,
  ); // Color único para todas las cards

  String nombreUsuario = "Cargando...";
  String rol = "Cargando...";
  String cargo = "";
  Map<String, dynamic> operacionesAutorizadas = {};
  Map<String, int> _catalogProcessIds = {};

  bool estaAutorizadoPara(String operacion) {
    return operacionesAutorizadas[operacion] == true;
  }

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final dbHelper = DatabaseHelper();
      final usuario = await dbHelper.getUserByDni(widget.dni);
      final catalogProcessIds = await _cargarCatalogoProcesos(dbHelper);
      print('Usuario cargado: $usuario');
      if (usuario != null) {
        final authorizedModules = await loadDashboardAuthorizationState(
          dni: widget.dni,
          databaseHelper: dbHelper,
          cachedUser: usuario,
        );

        String nombreCargo = '';
        final cargoId = usuario['cargo_id'];
        if (cargoId != null) {
          final sharedDb = await dbHelper.sharedCatalogDatabase;
          final rows = await sharedDb.query(
            'cargos',
            columns: ['nombre'],
            where: 'cargo_id = ?',
            whereArgs: [cargoId],
            limit: 1,
          );
          if (rows.isNotEmpty) {
            nombreCargo = rows.first['nombre']?.toString() ?? '';
          }
        }

        setState(() {
          nombreUsuario = '${usuario['nombres']} ${usuario['apellidos']}';
          rol = usuario['rol']?.toString() ?? '';
          cargo = nombreCargo;
          operacionesAutorizadas = authorizedModules;
          _catalogProcessIds = catalogProcessIds;
        });
      } else {
        setState(() {
          nombreUsuario = "Usuario no encontrado";
          rol = "sin rol";
          cargo = "sin cargo";
          _catalogProcessIds = catalogProcessIds;
        });
      }
    } catch (e) {
      print('Error obteniendo usuario: $e');
      setState(() {
        nombreUsuario = "Error al cargar usuario";
        rol = "Error al cargar rol";
        cargo = "Error al cargar cargo";
      });
    }
  }

  Future<Map<String, int>> _cargarCatalogoProcesos(
    DatabaseHelper dbHelper,
  ) async {
    final procesos = await dbHelper.getProcesos();
    final idsByName = <String, int>{};

    for (final proceso in procesos) {
      final id = proceso['id'] as int?;
      final nombre = proceso['nombre']?.toString();
      final nombreAbreviado = proceso['nombre_abreviado']?.toString();

      if (id == null) continue;
      if (nombre != null && nombre.trim().isNotEmpty) {
        idsByName[normalizeAuthorizationName(nombre)] = id;
      }
      if (nombreAbreviado != null && nombreAbreviado.trim().isNotEmpty) {
        idsByName[normalizeAuthorizationName(nombreAbreviado)] = id;
      }
    }

    return idsByName;
  }

  _DashboardModuleDefinition? _findModuleByTitle(String title) {
    for (final module in _dashboardModuleDefinitions) {
      if (module.title == title) return module;
    }
    return null;
  }

  Future<int?> _resolveProcesoIdForTitle(String title) async {
    if (_catalogProcessIds.isEmpty) {
      _catalogProcessIds = await _cargarCatalogoProcesos(DatabaseHelper());
    }

    final module = _findModuleByTitle(title);
    if (module == null) return null;

    for (final processName in module.processLookupNames) {
      final procesoId =
          _catalogProcessIds[normalizeAuthorizationName(processName)];
      if (procesoId != null) {
        return procesoId;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectionProvider>().isOnline;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 2,
        title: const Text(
          'Panel de Control',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
        backgroundColor: navbarColor,
        foregroundColor: Colors.white,
        actions: [
          // Botón de upload
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              icon: const Icon(Icons.cloud_upload),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SeccionesScreen()),
                );
              },
              tooltip: 'Subir reportes',
            ),
          ),
          // Menú
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'actualizar') {
                final isOnline = context.read<ConnectionProvider>().isOnline;
                if (!isOnline) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No hay conexión a internet. Conéctese para actualizar datos.',
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                await _actualizarDatos(context);
              } else if (value == 'mediciones') {
                await fetchExploracionesMina2();
              } else if (value == 'cerrar_sesion') {
                _showLogoutDialog(context);
              }
            },
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            itemBuilder: (context) => [
              _buildMenuItem(
                value: 'actualizar',
                icon: Icons.refresh,
                label: 'Actualizar datos',
                iconColor: Colors.blue,
              ),
              _buildMenuItem(
                value: 'mediciones',
                icon: Icons.science,
                label: 'Actualizar Mediciones',
                iconColor: Colors.purple,
              ),
              const PopupMenuDivider(),
              _buildMenuItem(
                value: 'cerrar_sesion',
                icon: Icons.exit_to_app,
                label: 'Cerrar sesión',
                iconColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header compacto con información del usuario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: navbarColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, size: 24, color: navbarColor),
                    ),
                    const SizedBox(width: 12),

                    // 👇 INFO USUARIO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreUsuario,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cargo.isEmpty ? 'Sin cargo asignado' : cargo,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 👇 ESTADO INTERNET
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOnline ? Icons.wifi : Icons.wifi_off,
                                size: 14,
                                color: isOnline ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOnline ? "Online" : "Offline",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOnline
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 📅 Fecha
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getCurrentDate(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Título de sección compacto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Módulos disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    '${_getModuleCount()} módulos',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grid de botones
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double width = constraints.maxWidth;
                    int columns;

                    if (width > 1000) {
                      columns = 6;
                    } else if (width > 800) {
                      columns = 5;
                    } else if (width > 600) {
                      columns = 4;
                    } else if (width > 400) {
                      columns = 3;
                    } else {
                      columns = 2;
                    }

                    List<Widget> buttons = _buildModuleButtons();

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9, // Tarjetas más compactas
                      ),
                      itemCount: buttons.length,
                      itemBuilder: (context, index) => buttons[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildModuleButtons() {
    List<Widget> buttons = [];

    final modules = [
      for (final module in _dashboardModuleDefinitions)
        if (estaAutorizadoPara(module.legacyKey))
          {'title': module.title, 'image': module.image},
    ];

    for (var module in modules) {
      buttons.add(
        ReportButton(
          title: module['title']!,
          imagePath: module['image']!,
          backgroundColor: navbarColor, // MISMO COLOR PARA TODAS
          onPressed: () async {
            // Acción según el módulo
            await _handleModulePress(module['title']!);
          },
        ),
      );
    }

    return buttons;
  }

  Future<void> _handleModulePress(String title) async {
    final resolvedProcesoId = await _resolveProcesoIdForTitle(title);
    if (!mounted) return;

    if (resolvedProcesoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se encontró el proceso configurado para "$title" en la tabla procesos.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    switch (title) {
      case 'PERFORACIÓN\nTALADROS LARGOS':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperacionListScreen(
              rolUsuario: rol,
              dniUsuario: widget.dni,
              config: OperacionScreenConfig(
                proceso: 'PERFORACIÓN TALADROS LARGOS',
                procesoId: resolvedProcesoId,
                dbSuffix: '',
                operacionNombreDb: 'TalLargo',
              ),
              onShowDialogoRegistro:
                  (
                    context,
                    turno,
                    estado,
                    procesoId,
                    categoriaId,
                    ultimaHora,
                    existingRecord,
                  ) => showRegistroOperacionDialog(
                    context: context,
                    dialog: RegistroOperacionDialog(
                      turno: turno,
                      selectedState: estado,
                      procesoId: procesoId,
                      categoriaId: categoriaId,
                      ultimaHoraRegistrada: ultimaHora,
                      existingRecord: existingRecord?.map(
                        (k, v) => MapEntry(k, v.toString()),
                      ),
                      onConfirm: (data) => Navigator.of(context).pop(data),
                    ),
                  ),
              onBuildDialogoPerforacion:
                  (
                    context,
                    operacionId,
                    estadoId,
                    datosIniciales,
                    fecha,
                    turno,
                    primaryColor,
                    onGuardar,
                  ) => tl.DialogoFormularioPerforacion(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    datosIniciales: datosIniciales,
                    estado: "OPERATIVO",
                    fecha: fecha,
                    turno: turno,
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildDialogoNoOperativo:
                  (
                    context,
                    operacionId,
                    estadoId,
                    estado,
                    primaryColor,
                    onGuardar,
                    datosIniciales,
                  ) => DialogoFormularioNoOperativo(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    estado: estado,
                    datosIniciales: datosIniciales,
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildConfirmarCierre: (primaryColor, onConfirmar) =>
                  DialogoConfirmarCierreRegistros(
                    primaryColor: primaryColor,
                    onConfirmar: onConfirmar,
                  ),
              onBuildCondicionesEquipo:
                  (operacionId, estado, condicionesData, primaryColor) =>
                      DialogoCondicionesEquipo(
                        operacionId: operacionId,
                        estado: estado,
                        condicionesData: condicionesData,
                        primaryColor: primaryColor,
                        onGuardar: (id, datos) =>
                            DatabaseHelper().updateCondicionesEquipo(id, datos),
                      ),
              onBuildCheckImagen:
                  (operacionId, estado, controlLlantasData, primaryColor) =>
                      DialogoCheckImagen(
                        operacionId: operacionId,
                        estado: estado,
                        controlLlantasData: controlLlantasData ?? {},
                        primaryColor: primaryColor,
                        onSave: (id, datos) => DatabaseHelper()
                            .updateControlLlantasTLargos(id, datos),
                      ),
              buildBotonesEstado: (onEstadoSeleccionado) =>
                  BotonesEstado(onEstadoSeleccionado: onEstadoSeleccionado),
              buildTablaOperaciones:
                  (
                    operaciones,
                    onVerDetalle,
                    onEditar,
                    onEliminar,
                    primaryColor,
                  ) => TablaOperaciones(
                    operaciones: operaciones,
                    onVerDetalle: onVerDetalle,
                    onEditar: onEditar,
                    onEliminar: onEliminar,
                    primaryColor: primaryColor,
                  ),
              buildBotonesAcciones:
                  ({
                    required onChecklistPressed,
                    required onHorometroPressed,
                    required onCerrarRegistrosPressed,
                    required onCondicionesEquipoPressed,
                    required onPresionLlantasPressed,
                    required primaryColor,
                    onChecklistTelemandoPressed,
                    onProgramaTrabajoPressed,
                  }) => BotonesAccionesInferiores(
                    onChecklistPressed: onChecklistPressed,
                    onHorometroPressed: onHorometroPressed,
                    onCerrarRegistrosPressed: onCerrarRegistrosPressed,
                    onCondicionesEquipoPressed: onCondicionesEquipoPressed,
                    onPresionLlantasPressed: onPresionLlantasPressed,
                    primaryColor: primaryColor,
                  ),
            ),
          ),
        );
        break;

      case 'PERFORACIÓN\nHORIZONTAL':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperacionListScreen(
              rolUsuario: rol,
              dniUsuario: widget.dni,
              config: OperacionScreenConfig(
                proceso: 'PERFORACIÓN HORIZONTAL',
                procesoId: resolvedProcesoId,
                dbSuffix: 'Horizontal',
                operacionNombreDb: 'TalHorizontal',
              ),
              onShowDialogoRegistro:
                  (
                    context,
                    turno,
                    estado,
                    procesoId,
                    categoriaId,
                    ultimaHora,
                    existingRecord,
                  ) => showRegistroOperacionDialog(
                    context: context,
                    dialog: RegistroOperacionDialog(
                      turno: turno,
                      selectedState: estado,
                      procesoId: procesoId,
                      categoriaId: categoriaId,
                      ultimaHoraRegistrada: ultimaHora,
                      existingRecord: existingRecord?.map(
                        (k, v) => MapEntry(k, v.toString()),
                      ),
                      onConfirm: (data) => Navigator.of(context).pop(data),
                    ),
                  ),
              onBuildDialogoPerforacion:
                  (
                    context,
                    operacionId,
                    estadoId,
                    datosIniciales,
                    fecha,
                    turno,
                    primaryColor,
                    onGuardar,
                  ) => th.DialogoFormularioPerforacion(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    datosIniciales: datosIniciales,
                    estado: "OPERATIVO",
                    fecha: fecha,
                    turno: turno,
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildDialogoNoOperativo:
                  (
                    context,
                    operacionId,
                    estadoId,
                    estado,
                    primaryColor,
                    onGuardar,
                    datosIniciales,
                  ) => DialogoFormularioNoOperativo(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    estado: estado,
                    datosIniciales: datosIniciales,
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildConfirmarCierre: (primaryColor, onConfirmar) =>
                  DialogoConfirmarCierreRegistros(
                    primaryColor: primaryColor,
                    onConfirmar: onConfirmar,
                  ),
              onBuildCondicionesEquipo:
                  (operacionId, estado, condicionesData, primaryColor) =>
                      DialogoCondicionesEquipo(
                        operacionId: operacionId,
                        estado: estado,
                        condicionesData: condicionesData,
                        primaryColor: primaryColor,
                        onGuardar: (id, datos) => DatabaseHelper()
                            .updateCondicionesEquipoHorizontal(id, datos),
                      ),
              onBuildCheckImagen:
                  (operacionId, estado, controlLlantasData, primaryColor) =>
                      DialogoCheckImagen(
                        operacionId: operacionId,
                        estado: estado,
                        controlLlantasData: controlLlantasData ?? {},
                        primaryColor: primaryColor,
                        onSave: (id, datos) => DatabaseHelper()
                            .updateControlLlantasHorizontal(id, datos),
                      ),
              buildBotonesEstado: (onEstadoSeleccionado) =>
                  BotonesEstado(onEstadoSeleccionado: onEstadoSeleccionado),
              buildTablaOperaciones:
                  (
                    operaciones,
                    onVerDetalle,
                    onEditar,
                    onEliminar,
                    primaryColor,
                  ) => TablaOperaciones(
                    operaciones: operaciones,
                    onVerDetalle: onVerDetalle,
                    onEditar: onEditar,
                    onEliminar: onEliminar,
                    primaryColor: primaryColor,
                  ),
              buildBotonesAcciones:
                  ({
                    required onChecklistPressed,
                    required onHorometroPressed,
                    required onCerrarRegistrosPressed,
                    required onCondicionesEquipoPressed,
                    required onPresionLlantasPressed,
                    required primaryColor,
                    onChecklistTelemandoPressed,
                    onProgramaTrabajoPressed,
                  }) => BotonesAccionesInferiores(
                    onChecklistPressed: onChecklistPressed,
                    onHorometroPressed: onHorometroPressed,
                    onCerrarRegistrosPressed: onCerrarRegistrosPressed,
                    onCondicionesEquipoPressed: onCondicionesEquipoPressed,
                    onPresionLlantasPressed: onPresionLlantasPressed,
                    primaryColor: primaryColor,
                  ),
            ),
          ),
        );
        break;

      case 'SOSTENIMIENTO':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperacionListScreen(
              rolUsuario: rol,
              dniUsuario: widget.dni,
              config: OperacionScreenConfig(
                proceso: 'SOSTENIMIENTO',
                procesoId: resolvedProcesoId,
                dbSuffix: 'Empernador',
                operacionNombreDb: 'Empernador',
              ),
              onShowDialogoRegistro:
                  (
                    context,
                    turno,
                    estado,
                    procesoId,
                    categoriaId,
                    ultimaHora,
                    existingRecord,
                  ) => showRegistroOperacionDialog(
                    context: context,
                    dialog: RegistroOperacionDialog(
                      turno: turno,
                      selectedState: estado,
                      procesoId: procesoId,
                      categoriaId: categoriaId,
                      ultimaHoraRegistrada: ultimaHora,
                      existingRecord: existingRecord?.map(
                        (k, v) => MapEntry(k, v.toString()),
                      ),
                      onConfirm: (data) => Navigator.of(context).pop(data),
                    ),
                  ),
              onBuildDialogoPerforacion:
                  (
                    context,
                    operacionId,
                    estadoId,
                    datosIniciales,
                    fecha,
                    turno,
                    primaryColor,
                    onGuardar,
                  ) => so.DialogoFormularioEmpernador(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    datosIniciales: datosIniciales,
                    estado: "OPERATIVO",
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildDialogoNoOperativo:
                  (
                    context,
                    operacionId,
                    estadoId,
                    estado,
                    primaryColor,
                    onGuardar,
                    datosIniciales,
                  ) => DialogoFormularioNoOperativo(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    estado: estado,
                    datosIniciales: datosIniciales,
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildConfirmarCierre: (primaryColor, onConfirmar) =>
                  DialogoConfirmarCierreRegistros(
                    primaryColor: primaryColor,
                    onConfirmar: onConfirmar,
                  ),
              onBuildCondicionesEquipo:
                  (operacionId, estado, condicionesData, primaryColor) =>
                      DialogoCondicionesEquipo(
                        operacionId: operacionId,
                        estado: estado,
                        condicionesData: condicionesData,
                        primaryColor: primaryColor,
                        onGuardar: (id, datos) => DatabaseHelper()
                            .updateCondicionesEquipoEmpernador(id, datos),
                      ),
              onBuildCheckImagen:
                  (operacionId, estado, controlLlantasData, primaryColor) =>
                      DialogoCheckImagen(
                        operacionId: operacionId,
                        estado: estado,
                        controlLlantasData: controlLlantasData ?? {},
                        primaryColor: primaryColor,
                        onSave: (id, datos) => DatabaseHelper()
                            .updateControlLlantasEmpernador(id, datos),
                      ),
              buildBotonesEstado: (onEstadoSeleccionado) =>
                  BotonesEstado(onEstadoSeleccionado: onEstadoSeleccionado),
              buildTablaOperaciones:
                  (
                    operaciones,
                    onVerDetalle,
                    onEditar,
                    onEliminar,
                    primaryColor,
                  ) => TablaOperaciones(
                    operaciones: operaciones,
                    onVerDetalle: onVerDetalle,
                    onEditar: onEditar,
                    onEliminar: onEliminar,
                    primaryColor: primaryColor,
                  ),
              buildBotonesAcciones:
                  ({
                    required onChecklistPressed,
                    required onHorometroPressed,
                    required onCerrarRegistrosPressed,
                    required onCondicionesEquipoPressed,
                    required onPresionLlantasPressed,
                    required primaryColor,
                    onChecklistTelemandoPressed,
                    onProgramaTrabajoPressed,
                  }) => BotonesAccionesInferiores(
                    onChecklistPressed: onChecklistPressed,
                    onHorometroPressed: onHorometroPressed,
                    onCerrarRegistrosPressed: onCerrarRegistrosPressed,
                    onCondicionesEquipoPressed: onCondicionesEquipoPressed,
                    onPresionLlantasPressed: onPresionLlantasPressed,
                    primaryColor: primaryColor,
                  ),
            ),
          ),
        );
        break;

      case 'CARGUÍO':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperacionListScreen(
              rolUsuario: rol,
              dniUsuario: widget.dni,
              config: OperacionScreenConfig(
                proceso: 'SCOOP',
                procesoId: resolvedProcesoId,
                dbSuffix: 'Scoop',
                operacionNombreDb: 'Scoop',
                hasChecklistTelemando: true,
                hasProgramaTrabajo: true,
              ),
              onShowDialogoRegistro:
                  (
                    context,
                    turno,
                    estado,
                    procesoId,
                    categoriaId,
                    ultimaHora,
                    existingRecord,
                  ) => showRegistroOperacionDialog(
                    context: context,
                    dialog: RegistroOperacionDialog(
                      turno: turno,
                      selectedState: estado,
                      procesoId: procesoId,
                      categoriaId: categoriaId,
                      ultimaHoraRegistrada: ultimaHora,
                      existingRecord: existingRecord?.map(
                        (k, v) => MapEntry(k, v.toString()),
                      ),
                      onConfirm: (data) => Navigator.of(context).pop(data),
                    ),
                  ),
              onBuildDialogoPerforacion:
                  (
                    context,
                    operacionId,
                    estadoId,
                    datosIniciales,
                    fecha,
                    turno,
                    primaryColor,
                    onGuardar,
                  ) => cs.DialogoFormularioPerforacion(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    datosIniciales: datosIniciales,
                    estado: "OPERATIVO",
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildDialogoNoOperativo:
                  (
                    context,
                    operacionId,
                    estadoId,
                    estado,
                    primaryColor,
                    onGuardar,
                    datosIniciales,
                  ) => DialogoFormularioNoOperativo(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    estado: estado,
                    datosIniciales: datosIniciales,
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildConfirmarCierre: (primaryColor, onConfirmar) =>
                  DialogoConfirmarCierreRegistros(
                    primaryColor: primaryColor,
                    onConfirmar: onConfirmar,
                  ),
              onBuildCondicionesEquipo:
                  (operacionId, estado, condicionesData, primaryColor) =>
                      DialogoCondicionesEquipo(
                        operacionId: operacionId,
                        estado: estado,
                        condicionesData: condicionesData,
                        primaryColor: primaryColor,
                        onGuardar: (id, datos) => DatabaseHelper()
                            .updateCondicionesEquipoCarguio(id, datos),
                      ),
              onBuildCheckImagen:
                  (operacionId, estado, controlLlantasData, primaryColor) =>
                      DialogoCheckImagen(
                        operacionId: operacionId,
                        estado: estado,
                        controlLlantasData: controlLlantasData ?? {},
                        primaryColor: primaryColor,
                        onSave: (id, datos) => DatabaseHelper()
                            .updateControlLlantasCarguio(id, datos),
                      ),
              buildBotonesEstado: (onEstadoSeleccionado) =>
                  BotonesEstado(onEstadoSeleccionado: onEstadoSeleccionado),
              buildTablaOperaciones:
                  (
                    operaciones,
                    onVerDetalle,
                    onEditar,
                    onEliminar,
                    primaryColor,
                  ) => TablaOperaciones(
                    operaciones: operaciones,
                    onVerDetalle: onVerDetalle,
                    onEditar: onEditar,
                    onEliminar: onEliminar,
                    primaryColor: primaryColor,
                  ),
              buildBotonesAcciones:
                  ({
                    required onChecklistPressed,
                    required onHorometroPressed,
                    required onCerrarRegistrosPressed,
                    required onCondicionesEquipoPressed,
                    required onPresionLlantasPressed,
                    required primaryColor,
                    onChecklistTelemandoPressed,
                    onProgramaTrabajoPressed,
                  }) => BotonesAccionesInferiores(
                    onChecklistPressed: onChecklistPressed,
                    onHorometroPressed: onHorometroPressed,
                    onCerrarRegistrosPressed: onCerrarRegistrosPressed,
                    onCondicionesEquipoPressed: onCondicionesEquipoPressed,
                    onPresionLlantasPressed: onPresionLlantasPressed,
                    primaryColor: primaryColor,
                  ),
            ),
          ),
        );
        break;

      case 'ACARREO':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperacionListScreen(
              rolUsuario: rol,
              dniUsuario: widget.dni,
              config: OperacionScreenConfig(
                proceso: 'ACARREO',
                procesoId: resolvedProcesoId,
                dbSuffix: 'Dumper',
                operacionNombreDb: 'Dumper',
                hasChecklistTelemando: true,
                hasProgramaTrabajo: true,
              ),
              onShowDialogoRegistro:
                  (
                    context,
                    turno,
                    estado,
                    procesoId,
                    categoriaId,
                    ultimaHora,
                    existingRecord,
                  ) => showRegistroOperacionDialog(
                    context: context,
                    dialog: RegistroOperacionDialog(
                      turno: turno,
                      selectedState: estado,
                      procesoId: procesoId,
                      categoriaId: categoriaId,
                      ultimaHoraRegistrada: ultimaHora,
                      existingRecord: existingRecord?.map(
                        (k, v) => MapEntry(k, v.toString()),
                      ),
                      onConfirm: (data) => Navigator.of(context).pop(data),
                    ),
                  ),
              onBuildDialogoPerforacion:
                  (
                    context,
                    operacionId,
                    estadoId,
                    datosIniciales,
                    fecha,
                    turno,
                    primaryColor,
                    onGuardar,
                  ) => ad.DialogoFormularioPerforacion(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    datosIniciales: datosIniciales,
                    estado: "OPERATIVO",
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildDialogoNoOperativo:
                  (
                    context,
                    operacionId,
                    estadoId,
                    estado,
                    primaryColor,
                    onGuardar,
                    datosIniciales,
                  ) => DialogoFormularioNoOperativo(
                    operacionId: operacionId,
                    estadoId: estadoId,
                    estado: estado,
                    datosIniciales: datosIniciales,
                    primaryColor: primaryColor,
                    onGuardar: onGuardar,
                  ),
              onBuildConfirmarCierre: (primaryColor, onConfirmar) =>
                  DialogoConfirmarCierreRegistros(
                    primaryColor: primaryColor,
                    onConfirmar: onConfirmar,
                  ),
              onBuildCondicionesEquipo:
                  (operacionId, estado, condicionesData, primaryColor) =>
                      DialogoCondicionesEquipo(
                        operacionId: operacionId,
                        estado: estado,
                        condicionesData: condicionesData,
                        primaryColor: primaryColor,
                        onGuardar: (id, datos) => DatabaseHelper()
                            .updateCondicionesEquipoDumper(id, datos),
                      ),
              onBuildCheckImagen:
                  (operacionId, estado, controlLlantasData, primaryColor) =>
                      DialogoCheckImagen(
                        operacionId: operacionId,
                        estado: estado,
                        controlLlantasData: controlLlantasData ?? {},
                        primaryColor: primaryColor,
                        onSave: (id, datos) => DatabaseHelper()
                            .updateControlLlantasDumper(id, datos),
                      ),
              buildBotonesEstado: (onEstadoSeleccionado) =>
                  BotonesEstado(onEstadoSeleccionado: onEstadoSeleccionado),
              buildTablaOperaciones:
                  (
                    operaciones,
                    onVerDetalle,
                    onEditar,
                    onEliminar,
                    primaryColor,
                  ) => TablaOperaciones(
                    operaciones: operaciones,
                    onVerDetalle: onVerDetalle,
                    onEditar: onEditar,
                    onEliminar: onEliminar,
                    primaryColor: primaryColor,
                  ),
              buildBotonesAcciones:
                  ({
                    required onChecklistPressed,
                    required onHorometroPressed,
                    required onCerrarRegistrosPressed,
                    required onCondicionesEquipoPressed,
                    required onPresionLlantasPressed,
                    required primaryColor,
                    onChecklistTelemandoPressed,
                    onProgramaTrabajoPressed,
                  }) => BotonesAccionesInferiores(
                    onChecklistPressed: onChecklistPressed,
                    onHorometroPressed: onHorometroPressed,
                    onCerrarRegistrosPressed: onCerrarRegistrosPressed,
                    onCondicionesEquipoPressed: onCondicionesEquipoPressed,
                    onPresionLlantasPressed: onPresionLlantasPressed,
                    primaryColor: primaryColor,
                  ),
            ),
          ),
        );
        break;

      case 'MEDICIONES':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Selecc_Tipo_explo()),
        );
        break;

      case 'SERVICIOS\nAUXILIARES':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiciosAuxiliaresScreen(
              rolUsuario: rol,
              dniUsuario: widget.dni,
            ),
          ),
        );
        break;

      default:
        print('Módulo no configurado');
    }
  }

  int _getModuleCount() {
    return _dashboardModuleDefinitions
        .where((module) => estaAutorizadoPara(module.legacyKey))
        .length;
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _actualizarDatos(BuildContext context) async {
    // Definir las opciones disponibles

    // Mostrar diálogo de selección mejorado
    final opcionesSeleccionadas = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => ActualizacionDialog(
        primaryColor: navbarColor, // Tu color primario
      ),
    );

    // Si el usuario cancela o no selecciona nada, salir
    if (opcionesSeleccionadas == null || opcionesSeleccionadas.isEmpty) {
      return;
    }
    print("token${widget.token}");
    // Crear y ejecutar el servicio de actualización
    final actualizacionService = ActualizacionService(
      context: context,
      token: widget.token,
      dni: widget.dni,
    );

    await actualizacionService.ejecutarActualizacion(opcionesSeleccionadas);
    await _cargarNombreUsuario();
  }

  Future<void> fetchExploracionesMina2() async {
    try {
      final apiService = ApiServiceExploracion_Mina2(); // ✅ Crear una instancia

      final tipos = await apiService.fetchExploracionesMina2(widget.token);
      print("Tipos de Perforación cargados correctamente: $tipos");

      // Verificar si los datos se almacenaron correctamente
      final dbHelper = DatabaseHelper();
      final tiposBD = await dbHelper.getAll('tipo_perforaciones');
      print("Tipos de Perforación en la base de datos local: $tiposBD");
    } catch (e) {
      print("Error al cargar los tipos de perforación: $e");
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro que desea cerrar la sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
