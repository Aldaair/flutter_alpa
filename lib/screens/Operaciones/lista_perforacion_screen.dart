import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/DimTurno.dart';
import 'package:i_miner/screens/widgets/dialogo_checklist.dart';
import 'package:i_miner/screens/widgets/dialogo_horometro.dart';
import 'package:i_miner/screens/widgets/operacion_card.dart';
import 'package:i_miner/screens/widgets/operacion_card_config.dart';
import 'package:i_miner/core/checklist_helper.dart';

// ======== CONFIG CLASS ========
class OperacionScreenConfig {
  final String proceso;
  final int procesoId;
  final String dbSuffix;
  final String operacionNombreDb;
  final bool hasChecklistTelemando;
  final bool hasProgramaTrabajo;
  final bool mostrarModelo;
  final bool usarAutorizacion;

  const OperacionScreenConfig({
    required this.proceso,
    required this.procesoId,
    required this.dbSuffix,
    required this.operacionNombreDb,
    this.hasChecklistTelemando = false,
    this.hasProgramaTrabajo = false,
    this.mostrarModelo = true,
    this.usarAutorizacion = true,
  });
}

// ======== CALLBACK TYPEDEFS ========
typedef DialogoRegistroBuilder =
    Future<Map<String, dynamic>?> Function(
      BuildContext context,
      String turno,
      String estado,
      int procesoId,
      int categoriaId,
      String? ultimaHora,
      Map<String, dynamic>? existingRecord,
    );

typedef DialogoPerforacionBuilder =
    Widget Function(
      BuildContext context,
      int operacionId,
      int estadoId,
      Map<String, dynamic>? datosIniciales,
      String fecha,
      String turno,
      Color primaryColor,
      Function(Map<String, dynamic>) onGuardar,
    );

typedef DialogoNoOperativoBuilder =
    Widget Function(
      BuildContext context,
      int operacionId,
      int estadoId,
      String estado,
      Color primaryColor,
      Function(Map<String, dynamic>) onGuardar,
      Map<String, dynamic>? datosIniciales,
    );

typedef ConfirmarCierreBuilder =
    Widget Function(Color primaryColor, VoidCallback onConfirmar);

typedef CondicionesEquipoBuilder =
    Widget Function(
      int operacionId,
      String estado,
      Map<String, dynamic>? condicionesData,
      Color primaryColor,
    );

typedef CheckImagenBuilder =
    Widget Function(
      int operacionId,
      String estado,
      Map<String, dynamic>? controlLlantasData,
      Color primaryColor,
    );

typedef BotonesEstadoBuilder =
    Widget Function(Function(String, int) onEstadoSeleccionado);

typedef TablaOperacionesBuilder =
    Widget Function(
      List<Map<String, dynamic>> operaciones,
      Function(Map<String, dynamic>) onVerDetalle,
      Function(Map<String, dynamic>) onEditar,
      Function(Map<String, dynamic>) onEliminar,
      Color primaryColor,
    );

typedef BotonesAccionesBuilder =
    Widget Function({
      required VoidCallback onChecklistPressed,
      required VoidCallback onHorometroPressed,
      required VoidCallback onCerrarRegistrosPressed,
      required VoidCallback onCondicionesEquipoPressed,
      required VoidCallback onPresionLlantasPressed,
      required Color primaryColor,
      VoidCallback? onChecklistTelemandoPressed,
      VoidCallback? onProgramaTrabajoPressed,
      bool isCerrado,
    });

// ======== GENERIC WIDGET ========
class OperacionListScreen extends StatefulWidget {
  final String? rolUsuario;
  final String? dniUsuario;
  final OperacionScreenConfig config;

  final DialogoRegistroBuilder onShowDialogoRegistro;
  final DialogoPerforacionBuilder onBuildDialogoPerforacion;
  final DialogoNoOperativoBuilder onBuildDialogoNoOperativo;
  final ConfirmarCierreBuilder onBuildConfirmarCierre;
  final CondicionesEquipoBuilder onBuildCondicionesEquipo;
  final CheckImagenBuilder onBuildCheckImagen;

  final BotonesEstadoBuilder buildBotonesEstado;
  final TablaOperacionesBuilder buildTablaOperaciones;
  final BotonesAccionesBuilder buildBotonesAcciones;

  final void Function(
    int operacionId,
    String estado,
    Color primaryColor,
    BuildContext context,
  )?
  onChecklistTelemando;
  final void Function(
    int operacionId,
    String estado,
    Color primaryColor,
    BuildContext context,
  )?
  onProgramaTrabajo;

  const OperacionListScreen({
    super.key,
    this.rolUsuario,
    this.dniUsuario,
    required this.config,
    required this.onShowDialogoRegistro,
    required this.onBuildDialogoPerforacion,
    required this.onBuildDialogoNoOperativo,
    required this.onBuildConfirmarCierre,
    required this.onBuildCondicionesEquipo,
    required this.onBuildCheckImagen,
    required this.buildBotonesEstado,
    required this.buildTablaOperaciones,
    required this.buildBotonesAcciones,
    this.onChecklistTelemando,
    this.onProgramaTrabajo,
  });

  @override
  State<OperacionListScreen> createState() => _OperacionListScreenState();
}

class _OperacionListScreenState extends State<OperacionListScreen> {
  final Color primaryColor = const Color(0xFF1B5E6B);

  String fechaActual = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? selectedTurno;
  int? operacionId;
  List<Map<String, dynamic>> operaciones = [];
  Map<String, dynamic>? operacionActual;
  List<Map<String, dynamic>> masterOperators = [];
  int? selectedOperatorId;
  bool _canSelectOperators = false;
  List<DimTurno> _turnosCatalogo = [];

  List<Map<String, dynamic>> operacionesTabla = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  bool get _isMaster => _canSelectOperators;

  DatabaseHelper get _db => DatabaseHelper();
  String get _s => widget.config.dbSuffix;
  String get _n => widget.config.operacionNombreDb;

  String get _tableName {
    switch (_s) {
      case 'Horizontal':
        return 'Operacion_tal_horizontal';
      case 'Dumper':
        return 'Operacion_dumper';
      case 'Carguio':
        return 'Operacion_carguio';
      case 'Scissor':
        return 'Operacion_scissor';
      case 'Anfochanger':
        return 'Operacion_anfochanger';
      case 'Empernador':
        return 'Operacion_empernador';
      case 'RompeBaco':
        return 'Operacion_rompe_baco';
      case 'Scalamin':
        return 'Operacion_scalamin';
      default:
        return 'Operacion_tal_largo';
    }
  }

  Future<void> _initializeScreen() async {
    _turnosCatalogo = await _db.getDimTurnos();
    selectedTurno = _resolverTurnoActual();
    if (widget.dniUsuario != null) {
      final puedeSeleccionar = await _db.userHasCargo(widget.dniUsuario!, [
        'JEFE DE GUARDIA',
        'SUPERVISOR',
      ]);
      if (!mounted) return;
      setState(() {
        _canSelectOperators = puedeSeleccionar;
      });
    }
    if (_canSelectOperators) {
      await _loadMasterOperators();
    }
    await _fetchOperacionData();
  }

  int? _resolverTurnoId(String? turnoNombre) {
    if (turnoNombre == null) return null;
    final buscado = _normalizarClave(turnoNombre);
    for (final turno in _turnosCatalogo) {
      if (_normalizarClave(turno.nombre) == buscado ||
          _normalizarClave(turno.codigo) == buscado) {
        return turno.turnoId;
      }
    }
    return null;
  }

  String _normalizarClave(String? value) {
    if (value == null) return '';
    const replacements = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'á': 'A',
      'é': 'E',
      'í': 'I',
      'ó': 'O',
      'ú': 'U',
      'ü': 'U',
    };
    final buffer = StringBuffer();
    for (final rune in value.trim().runes) {
      buffer.write(
        replacements[String.fromCharCode(rune)] ?? String.fromCharCode(rune),
      );
    }
    return buffer.toString().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<int?> _resolveCurrentOperatorId(DatabaseHelper dbHelper) async {
    if (widget.dniUsuario == null) {
      return null;
    }
    final usuario = await dbHelper.getUserByDni(widget.dniUsuario!);
    return usuario?['id'] as int?;
  }

  Future<void> _loadMasterOperators() async {
    final dbHelper = DatabaseHelper();
    final operators = await dbHelper.getKnownOperators();
    final currentOperatorId = await _resolveCurrentOperatorId(dbHelper);

    if (!mounted) return;

    setState(() {
      masterOperators = operators;
      selectedOperatorId =
          currentOperatorId ??
          (operators.isNotEmpty ? operators.first['id'] as int? : null);
    });
  }

  String? _selectedOperatorName() {
    final selected = masterOperators.where(
      (operator) => operator['id'] == selectedOperatorId,
    );
    if (selected.isEmpty) return null;
    final operator = selected.first;
    return '${operator['nombres'] ?? ''} ${operator['apellidos'] ?? ''}'.trim();
  }

  String? _resolverTurnoActual() {
    if (_turnosCatalogo.isEmpty) return null;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    for (final turno in _turnosCatalogo) {
      if (_turnoContiene(turno, currentMinutes)) {
        return turno.nombre;
      }
    }
    return _turnosCatalogo.isNotEmpty ? _turnosCatalogo.first.nombre : null;
  }

  bool _turnoContiene(DimTurno turno, int currentMinutes) {
    final inicio = _parseHorario(turno.horarioInicio);
    final fin = _parseHorario(turno.horarioFin);
    if (inicio == null || fin == null) return false;
    if (inicio <= fin) {
      return currentMinutes >= inicio && currentMinutes < fin;
    } else {
      return currentMinutes >= inicio || currentMinutes < fin;
    }
  }

  int? _parseHorario(String? horario) {
    if (horario == null) return null;
    final parts = horario.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  // ======== DB DISPATCH METHODS ========

  Future<List<Map<String, dynamic>>> _fetchOperacionesDb(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    switch (_n) {
      case 'TalLargo':
        if (operadorId != null) {
          return _db.getOperacionTalLargoByTurnoAndFecha(
            turnoId,
            fecha,
            operadorId: operadorId,
          );
        }
        return _db.getOperacionTalLargoByTurnoAndFechaMaster(turnoId, fecha);
      case 'TalHorizontal':
        if (operadorId != null) {
          return _db.getOperacionTalHorizontalByTurnoAndFecha(
            turnoId,
            fecha,
            operadorId: operadorId,
          );
        }
        return _db.getOperacionTalHorizontalByTurnoAndFechaMaster(
          turnoId,
          fecha,
        );
      case 'Dumper':
        if (operadorId != null) {
          return _db.getOperacionDumperByTurnoAndFecha(
            turnoId,
            fecha,
            operadorId: operadorId,
          );
        }
        return _db.getOperacionDumperByTurnoAndFechaMaster(turnoId, fecha);
      case 'Carguio':
        if (operadorId != null) {
          return _db.getOperacionCarguioByTurnoAndFecha(
            turnoId,
            fecha,
            operadorId: operadorId,
          );
        }
        return _db.getOperacionCarguioByTurnoAndFechaMaster(turnoId, fecha);
      case 'Scissor':
        if (operadorId != null) {
          return _db.getOperacionScissorByTurnoAndFecha(
            turnoId,
            fecha,
            operadorId: operadorId,
          );
        }
        return _db.getOperacionScissorByTurnoAndFechaMaster(turnoId, fecha);
      case 'Anfochanger':
        if (operadorId != null) {
          return _db.getOperacionAnfochangerByTurnoAndFecha(
            turnoId,
            fecha,
            operadorId: operadorId,
          );
        }
        return _db.getOperacionAnfochangerByTurnoAndFechaMaster(turnoId, fecha);
      case 'Empernador':
        if (operadorId != null) {
          return _db.getOperacionEmpernadorByTurnoAndFecha(
            turnoId,
            fecha,
            operadorId: operadorId,
          );
        }
        return _db.getOperacionEmpernadorByTurnoAndFechaMaster(turnoId, fecha);
      case 'RompeBaco':
        if (operadorId != null) {
          return _db.getOperacionRompeBacoByTurnoAndFecha(
            turnoId,
            fecha,
            operadorId: operadorId,
          );
        }
        return _db.getOperacionRompeBacoByTurnoAndFechaMaster(turnoId, fecha);
      case 'Scalamin':
        if (operadorId != null) {
          return _db.getOperacionScalaminByTurnoAndFecha(
            turnoId,
            fecha,
            operadorId: operadorId,
          );
        }
        return _db.getOperacionScalaminByTurnoAndFechaMaster(turnoId, fecha);
      default:
        throw Exception('Unknown operacionNombreDb: $_n');
    }
  }

  Future<void> _insertOperacionDb(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> checkListJson,
  ) async {
    switch (_n) {
      case 'TalLargo':
        await _db.insertOperacionTalLargo(
          data['fecha'],
          turno: data['turno'] ?? '',
          operador: data['operador'] ?? '',
          jefeGuardia: data['jefe_guardia'] ?? data['jefeGuardia'] ?? '',
          equipo: data['equipo'] ?? '',
          registradorNombre: data['registrador'] ?? '',
          actorOperadorId: data['actor_operador_id'] as int?,
          operadorId: data['operador_id'] as int?,
          equipoId: data['equipo_id'] as int?,
          turnoId: data['turno_id'] as int?,
          registradorUsuarioId:
              (data['registrador_id'] ?? data['registrador_usuario_id'])
                  as int?,
          jefeGuardiaId: data['jefe_guardia_id'] as int?,
          checkListJson: checkListJson,
        );
      case 'TalHorizontal':
        await _db.insertOperacionTalHorizontal(
          data['fecha'],
          data['turno'] ?? '',
          data['seccion'] ?? '',
          data['operador'] ?? '',
          data['jefeGuardia'] ?? '',
          data['equipo'] ?? '',
          data['codigo'] ?? '',
          data['modelo'] ?? '',
          equipoId: data['equipo_id'] as int?,
          actorOperadorId: data['actor_operador_id'] as int?,
          operadorId: data['operador_id'] as int?,
          turnoId: data['turno_id'] as int?,
          registradorNombre: data['registrador'] ?? '',
          registradorUsuarioId:
              (data['registrador_id'] ?? data['registrador_usuario_id'])
                  as int?,
          jefeGuardiaId: data['jefe_guardia_id'] as int?,
          checkListJson: checkListJson,
        );
      case 'Dumper':
        await _db.insertOperacionDumper(
          data['fecha'],
          data['turno'] ?? '',
          data['seccion'] ?? '',
          data['operador'] ?? '',
          data['jefe_guardia'] ?? '',
          data['equipo'] ?? '',
          data['n_equipo'] ?? '',
          data['capacidad'] ?? '',
          data['tipo_equipo'] ?? '',
          equipoId: data['equipo_id'] as int?,
          actorOperadorId: data['actor_operador_id'] as int?,
          operadorId: data['operador_id'] as int?,
          turnoId: data['turno_id'] as int?,
          registradorNombre: data['registrador'] ?? '',
          registradorUsuarioId:
              (data['registrador_id'] ?? data['registrador_usuario_id'])
                  as int?,
          jefeGuardiaId: data['jefe_guardia_id'] as int?,
          checkListJson: checkListJson,
        );
      case 'Carguio':
        await _db.insertOperacionCarguio(
          data['fecha'],
          data['turno'] ?? '',
          data['seccion'] ?? '',
          data['operador'] ?? '',
          data['jefe_guardia'] ?? '',
          data['equipo'] ?? '',
          data['n_equipo'] ?? '',
          data['capacidad'] ?? '',
          data['tipo_equipo'] ?? '',
          equipoId: data['equipo_id'] as int?,
          actorOperadorId: data['actor_operador_id'] as int?,
          operadorId: data['operador_id'] as int?,
          turnoId: data['turno_id'] as int?,
          registradorNombre: data['registrador'] ?? '',
          registradorUsuarioId:
              (data['registrador_id'] ?? data['registrador_usuario_id'])
                  as int?,
          jefeGuardiaId: data['jefe_guardia_id'] as int?,
          checkListJson: checkListJson,
        );
      case 'Empernador':
        await _db.insertOperacionEmpernador(
          data['fecha'],
          data['turno'] ?? '',
          data['seccion'] ?? '',
          data['operador'] ?? '',
          data['jefeGuardia'] ?? '',
          data['equipo'] ?? '',
          data['codigo'] ?? '',
          data['modelo'] ?? '',
          equipoId: data['equipo_id'] as int?,
          actorOperadorId: data['actor_operador_id'] as int?,
          operadorId: data['operador_id'] as int?,
          turnoId: data['turno_id'] as int?,
          registradorNombre: data['registrador'] ?? '',
          registradorUsuarioId:
              (data['registrador_id'] ?? data['registrador_usuario_id'])
                  as int?,
          jefeGuardiaId: data['jefe_guardia_id'] as int?,
          checkListJson: checkListJson,
        );
      case 'RompeBaco':
        await _db.insertOperacionRompeBaco(
          data['fecha'],
          data['turno'] ?? '',
          data['operador'] ?? '',
          data['jefeGuardia'] ?? '',
          data['equipo'] ?? '',
          data['codigo'] ?? '',
          equipoId: data['equipo_id'] as int?,
          actorOperadorId: data['actor_operador_id'] as int?,
          operadorId: data['operador_id'] as int?,
          turnoId: data['turno_id'] as int?,
          registradorNombre: data['registrador'] ?? '',
          registradorUsuarioId:
              (data['registrador_id'] ?? data['registrador_usuario_id'])
                  as int?,
          jefeGuardiaId: data['jefe_guardia_id'] as int?,
          checkListJson: checkListJson,
        );
      case 'Scalamin':
        await _db.insertOperacionScalamin(
          data['fecha'],
          data['turno'] ?? '',
          data['operador'] ?? '',
          data['jefeGuardia'] ?? '',
          data['equipo'] ?? '',
          data['codigo'] ?? '',
          equipoId: data['equipo_id'] as int?,
          actorOperadorId: data['actor_operador_id'] as int?,
          operadorId: data['operador_id'] as int?,
          turnoId: data['turno_id'] as int?,
          registradorNombre: data['registrador'] ?? '',
          registradorUsuarioId:
              (data['registrador_id'] ?? data['registrador_usuario_id'])
                  as int?,
          jefeGuardiaId: data['jefe_guardia_id'] as int?,
          checkListJson: checkListJson,
        );
      case 'Scissor':
        await _db.insertOperacionScissor(
          data['fecha'],
          data['turno'] ?? '',
          data['operador'] ?? '',
          data['jefeGuardia'] ?? '',
          data['equipo'] ?? '',
          data['codigo'] ?? '',
          equipoId: data['equipo_id'] as int?,
          actorOperadorId: data['actor_operador_id'] as int?,
          operadorId: data['operador_id'] as int?,
          turnoId: data['turno_id'] as int?,
          registradorNombre: data['registrador'] ?? '',
          registradorUsuarioId:
              (data['registrador_id'] ?? data['registrador_usuario_id'])
                  as int?,
          jefeGuardiaId: data['jefe_guardia_id'] as int?,
          checkListJson: checkListJson,
        );
      case 'Anfochanger':
        await _db.insertOperacionAnfochanger(
          data['fecha'],
          data['turno'] ?? '',
          data['operador'] ?? '',
          data['jefeGuardia'] ?? '',
          data['equipo'] ?? '',
          data['codigo'] ?? '',
          equipoId: data['equipo_id'] as int?,
          actorOperadorId: data['actor_operador_id'] as int?,
          operadorId: data['operador_id'] as int?,
          turnoId: data['turno_id'] as int?,
          registradorNombre: data['registrador'] ?? '',
          registradorUsuarioId:
              (data['registrador_id'] ?? data['registrador_usuario_id'])
                  as int?,
          jefeGuardiaId: data['jefe_guardia_id'] as int?,
          checkListJson: checkListJson,
        );
      default:
        throw Exception('Unknown operacionNombreDb for insert: $_n');
    }
  }

  Future<int> _eliminarOperacionFisico(int id) async {
    switch (_n) {
      case 'TalLargo':
        return await _db.eliminarOperacionTalLargoFisico(id);
      case 'TalHorizontal':
        return await _db.eliminarOperacionTalHorizontalFisico(id);
      case 'Dumper':
        return await _db.eliminarOperacionTalDumperFisico(id);
      case 'Carguio':
        return await _db.eliminarOperacionTalCarguioFisico(id);
      case 'Scissor':
        return await _db.eliminarOperacionTalScissorFisico(id);
      case 'Anfochanger':
        return await _db.eliminarOperacionTalAnfochangerFisico(id);
      case 'Empernador':
        return await _db.eliminarOperacionTalEmpernadorFisico(id);
      case 'RompeBaco':
        return await _db.eliminarOperacionTalRompeBacoFisico(id);
      case 'Scalamin':
        return await _db.eliminarOperacionTalScalaminFisico(id);
      default:
        throw Exception('Unknown operacionNombreDb: $_n');
    }
  }

  Future<bool> _updateEstadoDispatch(
    int opId,
    int estId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, dynamic>? operacion,
  }) {
    return _db.updateEstado(
      opId,
      estId,
      numero: numero,
      estado: estado,
      codigo: codigo,
      horaInicio: horaInicio,
      horaFinal: horaFinal,
      operacion: operacion,
      tableName: _tableName,
    );
  }

  Future<bool> _updateHoraFinalDispatch(int opId, int estId, String horaFinal) {
    return _db.updateHoraFinal(opId, estId, horaFinal, tableName: _tableName);
  }

  Future<bool> _deleteEstadoDispatch(int opId, int estId) {
    return _db.deleteEstado(opId, estId, tableName: _tableName);
  }

  Future<Map<String, dynamic>> _getHorometrosData(int operacionId) {
    switch (_n) {
      case 'TalLargo':
        return _db.getHorometrosByOperacionId(operacionId);
      case 'TalHorizontal':
        return _db.getHorometrosByOperacionIdHorizontal(operacionId);
      case 'Dumper':
        return _db.getHorometrosByOperacionIdDumper(operacionId);
      case 'Carguio':
        return _db.getHorometrosByOperacionIdCarguio(operacionId);
      case 'Scissor':
        return _db.getHorometrosByOperacionIdScissor(operacionId);
      case 'Anfochanger':
        return _db.getHorometrosByOperacionIdAnfochanger(operacionId);
      case 'Empernador':
        return _db.getHorometrosByOperacionIdEmpernador(operacionId);
      case 'RompeBaco':
        return _db.getHorometrosByOperacionIdRompeBaco(operacionId);
      case 'Scalamin':
        return _db.getHorometrosByOperacionIdScalamin(operacionId);
      default:
        throw Exception('Unknown operacionNombreDb for horometros: $_n');
    }
  }

  Future<bool> _updateHorometrosDispatch(
    int operacionId,
    Map<String, dynamic> horometros,
  ) {
    switch (_n) {
      case 'TalLargo':
        return _db.updateHorometros(operacionId, horometros);
      case 'TalHorizontal':
        return _db.updateHorometrosHorizontal(operacionId, horometros);
      case 'Dumper':
        return _db.updateHorometrosDumper(operacionId, horometros);
      case 'Carguio':
        return _db.updateHorometrosCarguio(operacionId, horometros);
      case 'Scissor':
        return _db.updateHorometrosScissor(operacionId, horometros);
      case 'Anfochanger':
        return _db.updateHorometrosAnfochanger(operacionId, horometros);
      case 'Empernador':
        return _db.updateHorometrosEmpernador(operacionId, horometros);
      case 'RompeBaco':
        return _db.updateHorometrosRompeBaco(operacionId, horometros);
      case 'Scalamin':
        return _db.updateHorometrosScalamin(operacionId, horometros);
      default:
        throw Exception('Unknown operacionNombreDb for horometros: $_n');
    }
  }

  Future<List<Map<String, dynamic>>> _getChecklistData(int operacionId) {
    switch (_n) {
      case 'TalLargo':
        return _db.getCheckListByOperacionId(operacionId);
      case 'TalHorizontal':
        return _db.getCheckListByOperacionIdHorizontal(operacionId);
      case 'Dumper':
        return _db.getCheckListByOperacionIdDumper(operacionId);
      case 'Carguio':
        return _db.getCheckListByOperacionIdCarguio(operacionId);
      case 'Scissor':
        return _db.getCheckListByOperacionIdScissor(operacionId);
      case 'Anfochanger':
        return _db.getCheckListByOperacionIdAnfochanger(operacionId);
      case 'Empernador':
        return _db.getCheckListByOperacionIdEmpernador(operacionId);
      case 'RompeBaco':
        return _db.getCheckListByOperacionIdRompeBaco(operacionId);
      case 'Scalamin':
        return _db.getCheckListByOperacionIdScalamin(operacionId);
      default:
        throw Exception('Unknown operacionNombreDb for checklist: $_n');
    }
  }

  Future<bool> _updateChecklistDispatch(
    int operacionId,
    List<Map<String, dynamic>> checklist,
  ) {
    switch (_n) {
      case 'TalLargo':
        return _db.updateCheckList(operacionId, checklist);
      case 'TalHorizontal':
        return _db.updateCheckListHorizontal(operacionId, checklist);
      case 'Dumper':
        return _db.updateCheckListDumper(operacionId, checklist);
      case 'Carguio':
        return _db.updateCheckListCarguio(operacionId, checklist);
      case 'Scissor':
        return _db.updateCheckListScissor(operacionId, checklist);
      case 'Anfochanger':
        return _db.updateCheckListAnfochanger(operacionId, checklist);
      case 'Empernador':
        return _db.updateCheckListEmpernador(operacionId, checklist);
      case 'RompeBaco':
        return _db.updateCheckListRompeBaco(operacionId, checklist);
      case 'Scalamin':
        return _db.updateCheckListScalamin(operacionId, checklist);
      default:
        throw Exception('Unknown operacionNombreDb for checklist: $_n');
    }
  }

  Future<Map<String, dynamic>> _getCondicionesEquipoData(int operacionId) {
    switch (_n) {
      case 'TalLargo':
        return _db.getCondicionesEquipoByOperacionId(operacionId);
      case 'TalHorizontal':
        return _db.getCondicionesEquipoByOperacionIdHorizontal(operacionId);
      case 'Dumper':
        return _db.getCondicionesEquipoByOperacionIdDumper(operacionId);
      case 'Carguio':
        return _db.getCondicionesEquipoByOperacionIdCarguio(operacionId);
      case 'Scissor':
        return _db.getCondicionesEquipoByOperacionIdScissor(operacionId);
      case 'Anfochanger':
        return _db.getCondicionesEquipoByOperacionIdAnfochanger(operacionId);
      case 'Empernador':
        return _db.getCondicionesEquipoByOperacionIdEmpernador(operacionId);
      case 'RompeBaco':
        return _db.getCondicionesEquipoByOperacionIdRompeBaco(operacionId);
      case 'Scalamin':
        return _db.getCondicionesEquipoByOperacionIdScalamin(operacionId);
      default:
        throw Exception(
          'Unknown operacionNombreDb for condiciones equipo: $_n',
        );
    }
  }

  Future<Map<String, dynamic>> _getControlLlantasData(int operacionId) {
    switch (_n) {
      case 'TalLargo':
        return _db.getControlLlantasByOperacionId(operacionId);
      case 'TalHorizontal':
        return _db.getControlLlantasByOperacionIdHorizontal(operacionId);
      case 'Dumper':
        return _db.getControlLlantasByOperacionIdDumper(operacionId);
      case 'Carguio':
        return _db.getControlLlantasByOperacionIdCarguio(operacionId);
      case 'Scissor':
        return _db.getControlLlantasByOperacionIdScissor(operacionId);
      case 'Anfochanger':
        return _db.getControlLlantasByOperacionIdAnfochanger(operacionId);
      case 'Empernador':
        return _db.getControlLlantasByOperacionIdEmpernador(operacionId);
      case 'RompeBaco':
        return _db.getControlLlantasByOperacionIdRompeBaco(operacionId);
      case 'Scalamin':
        return _db.getControlLlantasByOperacionIdScalamin(operacionId);
      default:
        throw Exception('Unknown operacionNombreDb for control llantas: $_n');
    }
  }

  // ======== FETCH OPERACION DATA ========

  Future<void> _fetchOperacionData() async {
    if (selectedTurno == null) {
      print("No hay turno seleccionado aún");
      return;
    }

    final turnoId = _resolverTurnoId(selectedTurno);
    if (turnoId == null) {
      print("No se pudo resolver turno_id para $selectedTurno");
      return;
    }

    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> data;

    if (_isMaster) {
      if (selectedOperatorId != null) {
        data = await _fetchOperacionesDb(
          turnoId,
          fechaActual,
          operadorId: selectedOperatorId,
        );
      } else {
        data = await _fetchOperacionesDb(turnoId, fechaActual);
      }
    } else {
      final operadorId = await _resolveCurrentOperatorId(dbHelper);
      data = await _fetchOperacionesDb(
        turnoId,
        fechaActual,
        operadorId: operadorId,
      );
    }

    print("Operaciones encontradas: $data");

    print(
      "🔍 _fetchOperacionData: data.length=${data.length}, selectedTurno=$selectedTurno, turnoId=$turnoId, fechaActual=$fechaActual",
    );
    setState(() {
      operaciones = data;
      if (data.isNotEmpty) {
        operacionActual = data.first;
        operacionId = data.first['id'];
        print(
          "✅ ID de operación guardado: $operacionId, turno=${data.first['turno_id']}, fecha=${data.first['fecha']}",
        );
      } else {
        operacionActual = null;
        operacionId = null;
        operacionesTabla = [];
        print(
          "❌ No se encontraron operaciones para turno=$selectedTurno (id=$turnoId), fecha=$fechaActual",
        );
      }
    });

    await _cargarEstadosOperacion();
  }

  Future<void> _cargarEstadosOperacion() async {
    if (operacionId == null) {
      setState(() {
        operacionesTabla = [];
      });
      return;
    }

    List<Map<String, dynamic>> estados = await DatabaseHelper()
        .getEstadosByOperacionId(operacionId!, tableName: _tableName);

    print("Estados obtenidos del registro: $estados");

    estados.sort((a, b) {
      int horaToMinutes(String hora) {
        if (hora.isEmpty) return 0;
        try {
          if (hora.contains(' ')) {
            hora = hora.split(' ')[1];
          }
          List<String> parts = hora.split(':');
          return int.parse(parts[0]) * 60 + int.parse(parts[1]);
        } catch (e) {
          return 0;
        }
      }

      int minutosA = horaToMinutes(a['hora_inicio']);
      int minutosB = horaToMinutes(b['hora_inicio']);
      return minutosA.compareTo(minutosB);
    });

    setState(() {
      operacionesTabla = estados.map((e) {
        return {
          'id': e['id'],
          'estado': e['estado'],
          'codigo': e['codigo'],
          'horaInicio': e['hora_inicio'],
          'horaFin': e['hora_final'],
          'numero': e['numero'],
        };
      }).toList();
    });
  }

  // ======== BUILD ========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            OperacionCard(
              fechaActual: fechaActual,
              selectedTurno: selectedTurno,
              dniUsuario: widget.dniUsuario,
              selectedOperatorName: _isMaster ? _selectedOperatorName() : null,
              selectedOperatorId: _isMaster ? selectedOperatorId : null,
              operators: _isMaster ? masterOperators : const [],
              canSelectOperators: _isMaster,
              onSelectedOperatorChanged: (value) async {
                setState(() {
                  selectedOperatorId = value;
                });
                await _fetchOperacionData();
              },
              operacionExistente: operacionActual,
              onTurnoChanged: (value) {
                setState(() {
                  selectedTurno = value;
                });
              },
              onFechaChanged: (value) {
                setState(() {
                  fechaActual = value;
                });
              },
              onOperacionCreada: _handleNuevaOperacion,
              primaryColor: primaryColor,
              config: OperacionCardConfig(
                proceso: widget.config.proceso,
                mostrarModelo: widget.config.mostrarModelo,
                usarAutorizacion: widget.config.usarAutorizacion,
                soloIds: false,
              ),
            ),

            const SizedBox(height: 16),

            widget.buildBotonesEstado(_mostrarDialogoEstado),

            const SizedBox(height: 8),

            Expanded(
              flex: 1,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: widget.buildTablaOperaciones(
                  operacionesTabla,
                  _verDetalleOperacion,
                  _editarOperacion,
                  _eliminarRegistroEstado,
                  primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 8),

            widget.buildBotonesAcciones(
              onChecklistPressed: _handleChecklist,
              onHorometroPressed: _handleHorometro,
              onCerrarRegistrosPressed: _handleCerrarRegistros,
              onCondicionesEquipoPressed: _handleCondicionesEquipo,
              onPresionLlantasPressed: _handlePresionLlantas,
              primaryColor: primaryColor,
              onChecklistTelemandoPressed: widget.config.hasChecklistTelemando
                  ? _handleChecklistTelemando
                  : null,
              onProgramaTrabajoPressed: widget.config.hasProgramaTrabajo
                  ? _handleProgramaTrabajo
                  : null,
              isCerrado: (operacionActual?['cerrado'] as int?) == 1,
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 2,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.horizontal_rule, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.config.proceso,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _refrescarDatos,
          tooltip: 'Refrescar',
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: _eliminarRegistro,
          tooltip: 'Eliminar',
        ),
      ],
    );
  }

  // ======== DELETE REGISTRO ========

  void _eliminarRegistro() {
    if (operacionId == null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width * 0.75,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Atención',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay registro seleccionado para eliminar.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width * 0.75,
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'Confirmar eliminación',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Deseas eliminar este registro?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      int filasAfectadas = await _eliminarOperacionFisico(
                        operacionId!,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            filasAfectadas > 0
                                ? 'Registro eliminado correctamente.'
                                : 'No se pudo eliminar el registro.',
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );

                      _refrescarDatos();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== DIALOGO ESTADO ========

  void _mostrarDialogoEstado(String estado, int categoriaId) async {
    print(
      "🔴 _mostrarDialogoEstado: operacionActual=$operacionActual, estado=$estado, _tableName=$_tableName",
    );
    if (operacionActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay una operación seleccionada'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    List<Map<String, dynamic>> todosLosEstados = await DatabaseHelper()
        .getEstadosByOperacionId(operacionActual!['id'], tableName: _tableName);

    print("📥 ESTADOS CRUDOS (BD):");
    for (var e in todosLosEstados) {
      print(
        "ID:${e['id']} | N°:${e['numero']} | Hora:${e['hora_inicio']} | Estado:${e['estado']}",
      );
    }

    todosLosEstados.sort((a, b) {
      int numA = a['numero'] ?? 0;
      int numB = b['numero'] ?? 0;
      return numA.compareTo(numB);
    });

    print("✅ ORDENADOS POR NUMERO:");
    for (var e in todosLosEstados) {
      print("N°${e['numero']} | Hora:${e['hora_inicio']}");
    }

    String? ultimaHora;
    if (todosLosEstados.isNotEmpty) {
      var ultimoEstado = todosLosEstados.last;
      ultimaHora = ultimoEstado['hora_inicio'];
      if (ultimaHora?.contains(' ') == true) {
        ultimaHora = ultimaHora!.split(' ')[1];
      }
      print("🟢 ÚLTIMA HORA CORRECTA: $ultimaHora");
    }

    List<Map<String, String>> codigosOperativos = [];
    if (operaciones.isNotEmpty) {
      codigosOperativos = operacionesTabla
          .where((op) => op['estado'] == estado)
          .map(
            (op) => {
              'id': op['id'].toString(),
              'numero': op['numero']?.toString() ?? '0',
              'codigo': op['codigo']?.toString() ?? '',
              'hora_inicio': op['horaInicio']?.toString() ?? '',
              'hora_final': op['horaFin']?.toString() ?? '',
              'estado': op['estado']?.toString() ?? '',
            },
          )
          .toList();
    }

    print("📤 ENVIANDO AL DIALOG:");
    print("Turno: ${operacionActual!['turno']}");
    print("Última hora enviada: $ultimaHora");

    final result = await widget.onShowDialogoRegistro(
      context,
      operacionActual!['turno'] ?? selectedTurno ?? 'DÍA',
      estado,
      widget.config.procesoId,
      categoriaId,
      ultimaHora,
      null,
    );

    if (result != null) {
      await _crearRegistroEstado(result, estado);
    }
  }

  // ======== VER DETALLE ========

  void _verDetalleOperacion(Map<String, dynamic> operacion) async {
    if (operacionActual == null) return;

    final estadoNombre = (operacion['estado'] ?? 'OPERATIVO')
        .toString()
        .toUpperCase();
    final cats = await DatabaseHelper().getCategoriasEstados();
    final catMatch = cats.firstWhere(
      (c) => (c['nombre']?.toString() ?? '').toUpperCase() == estadoNombre,
      orElse: () => {'id': 0},
    );
    final categoriaId = catMatch['id'] as int;

    final result = await widget.onShowDialogoRegistro(
      context,
      operacionActual!['turno'] ?? selectedTurno ?? 'DÍA',
      estadoNombre,
      widget.config.procesoId,
      categoriaId,
      null,
      {
        'id': operacion['id'].toString(),
        'numero': operacion['numero']?.toString() ?? '0',
        'codigo': operacion['codigo']?.toString() ?? '',
        'hora_inicio': operacion['hora_inicio']?.toString() ?? '',
        'hora_final': operacion['hora_final']?.toString() ?? '',
      },
    );

    if (result != null) {
      await _actualizarRegistroEstado(result, operacion);
    }
  }

  // ======== CREAR REGISTRO ESTADO ========

  Future<void> _crearRegistroEstado(
    Map<String, dynamic> data,
    String estado,
  ) async {
    try {
      if (operacionActual == null) return;

      List<Map<String, dynamic>> todosLosEstados = await DatabaseHelper()
          .getEstadosByOperacionId(
            operacionActual!['id'],
            tableName: _tableName,
          );

      DateTime? parseHoraCompleta(String horaStr) {
        try {
          if (horaStr.contains(' ')) {
            return DateTime.parse(horaStr);
          } else {
            String fechaHora = '$fechaActual $horaStr';
            return DateTime.parse(fechaHora);
          }
        } catch (e) {
          print('Error parseando hora: $horaStr');
          return null;
        }
      }

      todosLosEstados.sort((a, b) {
        DateTime? horaA = parseHoraCompleta(a['hora_inicio']);
        DateTime? horaB = parseHoraCompleta(b['hora_inicio']);
        if (horaA == null) return 1;
        if (horaB == null) return -1;
        return horaA.compareTo(horaB);
      });

      Map<String, dynamic>? ultimoEstadoActivo;
      for (var i = todosLosEstados.length - 1; i >= 0; i--) {
        if (todosLosEstados[i]['hora_final'] == null ||
            todosLosEstados[i]['hora_final'] == '') {
          ultimoEstadoActivo = todosLosEstados[i];
          break;
        }
      }

      if (ultimoEstadoActivo != null) {
        await _updateHoraFinalDispatch(
          operacionActual!['id'],
          ultimoEstadoActivo['id'],
          data['hora_inicio']!,
        );
      }

      List<Map<String, dynamic>> estadosDelMismoTipo = todosLosEstados
          .where((est) => est['estado'] == estado)
          .toList();

      int newNumber = estadosDelMismoTipo.isNotEmpty
          ? (estadosDelMismoTipo.last['numero'] as int) + 1
          : 1;

      Map<String, dynamic> operacionData = {
        'labor_id': data['labor_id'],
        'nivel': data['nivel'] ?? '',
        'tipo_labor': data['tipo_labor'] ?? '',
        'labor': data['labor'] ?? '',
        'ala': data['ala'] ?? '',
        'ala_id': data['ala_id'],
        'n_taladros_produccion': data['n_taladros_produccion'] ?? '',
        'metros_perforados_produccion':
            data['metros_perforados_produccion'] ?? '',
        'n_taladros_rimados': data['n_taladros_rimados'] ?? '',
        'metros_perforados_rimados': data['metros_perforados_rimados'] ?? '',
        'n_taladros_alivio': data['n_taladros_alivio'] ?? '',
        'metros_perforados_alivio': data['metros_perforados_alivio'] ?? '',
        'n_taladros_repaso': data['n_taladros_repaso'] ?? '',
        'metros_perforados_repaso': data['metros_perforados_repaso'] ?? '',
        'long_barras': data['long_barras'] ?? '',
        'num_barras': data['num_barras'] ?? '',
        'tipo_perforacion': data['tipo_perforacion'] ?? '',
        'tipo_perforacion_id': data['tipo_perforacion_id'],
      };

      Map<String, dynamic>? nuevoEstado = await DatabaseHelper().createEstado(
        operacionActual!['id'],
        estado,
        data['codigo']!,
        data['hora_inicio']!,
        operacion: operacionData,
        tableName: _tableName,
      );

      if (nuevoEstado != null) {
        _mostrarSnackBar("Registro guardado correctamente.", Colors.green);
        await _fetchOperacionData();
        _mostrarDialogoSecundario(nuevoEstado['id'], estado);
      }
    } catch (e) {
      _mostrarSnackBar("Error al crear registro: $e", Colors.red);
    }
  }

  // ======== ACTUALIZAR REGISTRO ESTADO ========

  Future<void> _actualizarRegistroEstado(
    Map<String, dynamic> data,
    Map<String, dynamic> operacionOriginal,
  ) async {
    try {
      if (operacionActual == null) return;

      DateTime? parseHoraCompleta(String horaStr) {
        try {
          if (horaStr.contains(' ')) {
            return DateTime.parse(horaStr);
          } else {
            String fechaHora = '$fechaActual $horaStr';
            return DateTime.parse(fechaHora);
          }
        } catch (e) {
          print('Error parseando hora: $horaStr');
          return null;
        }
      }

      List<Map<String, dynamic>> todosLosEstados = await DatabaseHelper()
          .getEstadosByOperacionId(
            operacionActual!['id'],
            tableName: _tableName,
          );

      todosLosEstados.sort((a, b) {
        DateTime? horaA = parseHoraCompleta(a['hora_inicio']);
        DateTime? horaB = parseHoraCompleta(b['hora_inicio']);
        if (horaA == null) return 1;
        if (horaB == null) return -1;
        return horaA.compareTo(horaB);
      });

      bool actualizado = await _updateEstadoDispatch(
        operacionActual!['id'],
        data['id'],
        numero: data['numero'],
        estado: data['estado'],
        codigo: data['codigo'],
        horaInicio: data['hora_inicio'],
        horaFinal: data['hora_final'] ?? '',
        operacion: {'nivel': data['nivel'] ?? '', 'labor': data['labor'] ?? ''},
      );

      if (actualizado) {
        todosLosEstados = await DatabaseHelper().getEstadosByOperacionId(
          operacionActual!['id'],
          tableName: _tableName,
        );

        todosLosEstados.sort((a, b) {
          DateTime? horaA = parseHoraCompleta(a['hora_inicio']);
          DateTime? horaB = parseHoraCompleta(b['hora_inicio']);
          if (horaA == null) return 1;
          if (horaB == null) return -1;
          return horaA.compareTo(horaB);
        });

        for (int i = 0; i < todosLosEstados.length; i++) {
          var estadoActual = todosLosEstados[i];

          if (i < todosLosEstados.length - 1) {
            var siguienteEstado = todosLosEstados[i + 1];
            if (estadoActual['hora_final'] != siguienteEstado['hora_inicio']) {
              await _updateHoraFinalDispatch(
                operacionActual!['id'],
                estadoActual['id'],
                siguienteEstado['hora_inicio'],
              );
            }
          } else {
            if (estadoActual['hora_final'] != "") {
              await _updateHoraFinalDispatch(
                operacionActual!['id'],
                estadoActual['id'],
                "",
              );
            }
          }
        }

        _mostrarSnackBar("Registro actualizado correctamente.", Colors.green);
        await _fetchOperacionData();
      }
    } catch (e) {
      _mostrarSnackBar("Error al actualizar: $e", Colors.red);
    }
  }

  Future<List<Map<String, dynamic>>> _getOperaciones() async {
    if (operacionActual == null) return [];
    return await DatabaseHelper().getEstadosByOperacionId(
      operacionActual!['id'],
      tableName: _tableName,
    );
  }

  // ======== DIALOGOS SECUNDARIOS ========

  void _mostrarDialogoSecundario(int estadoId, String estado) async {
    if (operacionActual == null) return;

    Future.delayed(Duration.zero, () {
      if (estado == "OPERATIVO") {
        _abrirDialogoPerforacion(estadoId);
      } else {
        _abrirDialogoNoOperativo(estadoId, estado);
      }
    });
  }

  Future<void> _abrirDialogoPerforacion(int estadoId) async {
    Map<String, dynamic> datosPerforacion = await DatabaseHelper()
        .getOperacionByEstadoId(
          operacionActual!['id'],
          estadoId,
          tableName: _tableName,
        );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return widget.onBuildDialogoPerforacion(
          context,
          operacionActual!['id'],
          estadoId,
          datosPerforacion,
          operacionActual!['fecha']?.toString() ?? fechaActual,
          operacionActual!['turno']?.toString() ?? selectedTurno ?? '',
          primaryColor,
          (datosActualizados) async {
            bool guardado = await DatabaseHelper().updateOperacionByEstadoId(
              operacionActual!['id'],
              estadoId,
              datosActualizados,
              tableName: _tableName,
            );
            if (guardado) {
              _mostrarSnackBar("Datos de perforación guardados", Colors.green);
              await _fetchOperacionData();
            } else {
              _mostrarSnackBar("Error al guardar", Colors.red);
            }
          },
        );
      },
    );
  }

  void _abrirDialogoNoOperativo(int estadoId, String estado) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return widget.onBuildDialogoNoOperativo(
          context,
          operacionActual!['id'],
          estadoId,
          estado,
          primaryColor,
          (datosActualizados) async {
            bool guardado = await DatabaseHelper().updateOperacionByEstadoId(
              operacionActual!['id'],
              estadoId,
              datosActualizados,
              tableName: _tableName,
            );
            if (guardado) {
              _mostrarSnackBar("Datos de perforación guardados", Colors.green);
              await _fetchOperacionData();
            } else {
              _mostrarSnackBar("Error al guardar", Colors.red);
            }
          },
          null,
        );
      },
    );
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ======== NUEVA OPERACION ========

  Future<void> _handleNuevaOperacion(Map<String, dynamic> data) async {
    DatabaseHelper dbHelper = DatabaseHelper();

    final turnoId = data['turno_id'] as int?;
    final operadorId = data['operador_id'] as int?;
    final fecha = data['fecha'] as String?;

    if (turnoId != null && operadorId != null && fecha != null) {
      final yaExiste = await dbHelper.existeOperacionEnTurno(
        tableName: _tableName,
        turnoId: turnoId,
        fecha: fecha,
        operadorId: operadorId,
      );
      if (yaExiste) {
        _mostrarSnackBar(
          'Este operador ya tiene una operación registrada en este turno',
          Colors.orange,
        );
        return;
      }
    }

    List<Map<String, dynamic>> checklistItems = await DatabaseHelper()
        .getCheckListByProceso(widget.config.proceso);

    List<Map<String, dynamic>> checkListJson = checklistItems.map((item) {
      return {'id': item['id'], 'decision': 1, 'observacion': ''};
    }).toList();

    await _insertOperacionDb(data, checkListJson);

    await _fetchOperacionData();
  }

  // ======== EDITAR OPERACION ========

  void _editarOperacion(Map<String, dynamic> operacion) async {
    if (operacionActual == null) return;

    String estado = operacion['estado'] ?? 'OPERATIVO';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (estado == "OPERATIVO") {
        await _editarOperacionOperativo(operacion);
      } else {
        await _editarOperacionNoOperativo(operacion, estado);
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _mostrarSnackBar("Error al cargar datos: $e", Colors.red);
    }
  }

  Future<void> _editarOperacionOperativo(Map<String, dynamic> operacion) async {
    Map<String, dynamic> datosPerforacion = await DatabaseHelper()
        .getOperacionByEstadoId(
          operacionActual!['id'],
          operacion['id'],
          tableName: _tableName,
        );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return widget.onBuildDialogoPerforacion(
          context,
          operacionActual!['id'],
          operacion['id'],
          datosPerforacion,
          operacionActual!['fecha']?.toString() ?? fechaActual,
          operacionActual!['turno']?.toString() ?? selectedTurno ?? '',
          primaryColor,
          (datosActualizados) async {
            bool guardado = await DatabaseHelper().updateOperacionByEstadoId(
              operacionActual!['id'],
              operacion['id'],
              datosActualizados,
              tableName: _tableName,
            );
            if (guardado) {
              _mostrarSnackBar(
                "Datos de perforación actualizados",
                Colors.green,
              );
              await _fetchOperacionData();
            } else {
              _mostrarSnackBar("Error al actualizar", Colors.red);
            }
          },
        );
      },
    );
  }

  Future<void> _editarOperacionNoOperativo(
    Map<String, dynamic> operacion,
    String estado,
  ) async {
    Map<String, dynamic> datosNoOperativo = await DatabaseHelper()
        .getOperacionByEstadoId(
          operacionActual!['id'],
          operacion['id'],
          tableName: _tableName,
        );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return widget.onBuildDialogoNoOperativo(
          context,
          operacionActual!['id'],
          operacion['id'],
          estado,
          primaryColor,
          (datosActualizados) async {
            bool guardado = await DatabaseHelper().updateOperacionByEstadoId(
              operacionActual!['id'],
              operacion['id'],
              datosActualizados,
              tableName: _tableName,
            );
            if (guardado) {
              _mostrarSnackBar("Datos de $estado actualizados", Colors.green);
              await _fetchOperacionData();
            } else {
              _mostrarSnackBar("Error al actualizar", Colors.red);
            }
          },
          datosNoOperativo,
        );
      },
    );
  }

  // ======== REFRESCAR ========

  void _refrescarDatos() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    await _fetchOperacionData();
    await _cargarEstadosOperacion();

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos actualizados'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ======== HANDLERS ========

  void _handleChecklist() async {
    if (operaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay operación seleccionada'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    var operacionActual = operaciones.first;
    int operacionId = operacionActual['id'];
    String estado = operacionActual['estado'] ?? 'OPERATIVO';

    List<Map<String, dynamic>> savedDecisions = await _getChecklistData(
      operacionId,
    );
    List<Map<String, dynamic>> checklistData =
        await ChecklistHelper.enrichForDisplay(
          proceso: widget.config.proceso,
          savedDecisions: savedDecisions,
        );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DialogoChecklist(
          operacionId: operacionId,
          estado: estado,
          checklistData: checklistData,
          onSaveChecklist: _updateChecklistDispatch,
          primaryColor: primaryColor,
        );
      },
    );
  }

  void _handleHorometro() async {
    if (operaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay operación seleccionada'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int operacionId = operacionActual!['id'];
    String estado = operacionActual!['estado'] ?? 'OPERATIVO';
    print("🔍 Operación actual para horómetro:");
    print(operacionActual);

    int? equipoId = operacionActual!['equipo_id'] as int?;
    if (equipoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('La operación no tiene un equipo asociado'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Map<String, dynamic> horometrosData = await _getHorometrosData(operacionId);

    final tipos = await DatabaseHelper().getEquipoHorometroTiposByEquipoId(
      equipoId,
    );
    final horometroDefs = tipos.isNotEmpty
        ? tipos
              .map(
                (t) => HorometroDef.fromRawNombre(
                  t['tipo_horometro_nombre'] as String,
                ),
              )
              .toList()
        : <HorometroDef>[];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DialogoHorometro(
          operacionId: operacionId,
          estado: estado,
          horometrosData: horometrosData,
          primaryColor: primaryColor,
          horometroDefs: horometroDefs,
          onSave: _updateHorometrosDispatch,
        );
      },
    );
  }

  void _handleCerrarRegistros() {
    if (operacionActual == null) {
      _mostrarSnackBar('No hay operación seleccionada', Colors.orange);
      return;
    }

    final parentContext = context;

    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return widget.onBuildConfirmarCierre(primaryColor, () async {
          Navigator.pop(dialogContext);

          showDialog(
            context: parentContext,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          try {
            var ultimoEstado = await DatabaseHelper()
                .getUltimoEstadoByOperacionId(
                  operacionActual!['id'],
                  tableName: _tableName,
                );

            if (ultimoEstado == null) {
              Navigator.pop(parentContext);
              _mostrarSnackBar(
                'No se puede cerrar: No hay estados registrados',
                Colors.red,
              );
              return;
            }

            String horaReservaInicio = (selectedTurno == 'DÍA')
                ? '17:30'
                : '05:30';

            bool actualizado = await _updateHoraFinalDispatch(
              operacionActual!['id'],
              ultimoEstado['id'],
              horaReservaInicio,
            );

            if (!actualizado) {
              throw Exception('No se pudo actualizar la hora final');
            }

            List<Map<String, dynamic>> todosLosEstados = await DatabaseHelper()
                .getEstadosByOperacionId(
                  operacionActual!['id'],
                  tableName: _tableName,
                );

            int newNumber = todosLosEstados.isNotEmpty
                ? (todosLosEstados.last['numero'] as int) + 1
                : 1;

            String horaReservaFinal = (selectedTurno == 'DÍA')
                ? '19:00'
                : '07:00';

            await DatabaseHelper().createReservaEstado(
              operacionActual!['id'],
              newNumber,
              horaReservaInicio,
              horaReservaFinal,
              tableName: _tableName,
            );

            await DatabaseHelper().cerrarOperacion(
              operacionActual!['id'],
              tableName: _tableName,
            );

            if (mounted) Navigator.pop(parentContext);

            _mostrarSnackBar(
              'Registro cerrado exitosamente. Se agregó estado RESERVA',
              Colors.green,
            );

            await _fetchOperacionData();
          } catch (e) {
            if (mounted) Navigator.pop(parentContext);
            _mostrarSnackBar('Error al cerrar registro: $e', Colors.red);
          }
        });
      },
    );
  }

  void _handleCondicionesEquipo() async {
    if (operaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay operación seleccionada'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    var operacionActual = operaciones.first;
    int operacionId = operacionActual['id'];
    String estado = operacionActual['estado'] ?? 'OPERATIVO';

    Map<String, dynamic> condicionesData = await _getCondicionesEquipoData(
      operacionId,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return widget.onBuildCondicionesEquipo(
          operacionId,
          estado,
          condicionesData,
          primaryColor,
        );
      },
    );
  }

  void _handlePresionLlantas() async {
    if (operaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay operación seleccionada'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    var operacionActual = operaciones.first;
    int operacionId = operacionActual['id'];
    String estado = operacionActual['estado'] ?? 'OPERATIVO';

    Map<String, dynamic> controlLlantas = await _getControlLlantasData(
      operacionId,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return widget.onBuildCheckImagen(
          operacionId,
          estado,
          controlLlantas,
          primaryColor,
        );
      },
    );
  }

  void _handleChecklistTelemando() {
    if (operaciones.isEmpty) {
      _mostrarSnackBar('No hay operación seleccionada', Colors.orange);
      return;
    }
    if (widget.onChecklistTelemando != null) {
      widget.onChecklistTelemando!(
        operacionActual!['id'],
        operacionActual!['estado'] ?? 'OPERATIVO',
        primaryColor,
        context,
      );
    } else {
      _mostrarSnackBar('Checklist Telemando no disponible', Colors.orange);
    }
  }

  void _handleProgramaTrabajo() {
    if (operaciones.isEmpty) {
      _mostrarSnackBar('No hay operación seleccionada', Colors.orange);
      return;
    }
    if (widget.onProgramaTrabajo != null) {
      widget.onProgramaTrabajo!(
        operacionActual!['id'],
        operacionActual!['estado'] ?? 'OPERATIVO',
        primaryColor,
        context,
      );
    } else {
      _mostrarSnackBar('Programa de Trabajo no disponible', Colors.orange);
    }
  }

  // ======== ELIMINAR REGISTRO ESTADO ========

  Future<void> _eliminarRegistroEstado(Map<String, dynamic> estado) async {
    try {
      if (operacionActual == null) return;

      List<Map<String, dynamic>> todosLosEstados = await DatabaseHelper()
          .getEstadosByOperacionId(
            operacionActual!['id'],
            tableName: _tableName,
          );

      int horaToMinutes(String? hora) {
        if (hora == null || hora.isEmpty) return 0;
        try {
          if (hora.contains(' ')) {
            hora = hora.split(' ')[1];
          }
          List<String> parts = hora.split(':');
          return int.parse(parts[0]) * 60 + int.parse(parts[1]);
        } catch (e) {
          return 0;
        }
      }

      String? horaEliminar = estado['hora_inicio']?.toString();
      int horaEliminarMinutos = horaToMinutes(horaEliminar);

      int estadosAEliminar = 0;
      List<Map<String, dynamic>> estadosPosteriores = [];

      for (var e in todosLosEstados) {
        String? horaEstado = e['hora_inicio']?.toString();
        int horaEstadoMinutos = horaToMinutes(horaEstado);

        if (horaEstadoMinutos >= horaEliminarMinutos) {
          estadosAEliminar++;
          if (e['id'] != estado['id']) {
            estadosPosteriores.add(e);
          }
        }
      }

      String mensajeConfirmacion =
          '¿Eliminar ${estado['estado']} #${estado['numero']}';
      if (estadosPosteriores.isNotEmpty) {
        mensajeConfirmacion +=
            '\n\ny TODOS los estados posteriores (${estadosPosteriores.length}):\n';
        for (var e in estadosPosteriores.take(3)) {
          mensajeConfirmacion +=
              '• ${e['estado']} #${e['numero']} (${e['hora_inicio']})\n';
        }
        if (estadosPosteriores.length > 3) {
          mensajeConfirmacion +=
              '• ... y ${estadosPosteriores.length - 3} más\n';
        }
      }
      mensajeConfirmacion += '\nTotal: $estadosAEliminar registro(s)';

      bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('⚠️ Confirmar eliminación en cascada'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Esta acción eliminará:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Esta acción no se puede deshacer.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar todo'),
              ),
            ],
          );
        },
      );

      if (confirmar != true) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      bool eliminado = await _deleteEstadoDispatch(
        operacionActual!['id'],
        estado['id'],
      );

      if (mounted) Navigator.pop(context);

      if (eliminado) {
        _mostrarSnackBar(
          "✅ Eliminados $estadosAEliminar registro(s) en cascada.",
          Colors.green,
        );
        await _fetchOperacionData();
        if (mounted) {
          setState(() {});
        }
      } else {
        _mostrarSnackBar("❌ Error al eliminar los registros.", Colors.red);
      }
    } catch (e) {
      print('Error detallado: $e');
      _mostrarSnackBar("Error al eliminar: $e", Colors.red);
    }
  }
}
