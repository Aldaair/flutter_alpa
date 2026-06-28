// --- Sub-models (fields inferred from DB/codebase, match JsonPropertyName) ---

class HorometrosRequest {
  final Map<String, dynamic> data;

  HorometrosRequest(this.data);

  factory HorometrosRequest.fromJson(Map<String, dynamic> json) =>
      HorometrosRequest(Map<String, dynamic>.from(json));

  Map<String, dynamic> toJson() => data;
}

class CondicionEquipoRequest {
  final Map<String, dynamic> data;

  CondicionEquipoRequest(this.data);

  factory CondicionEquipoRequest.fromJson(Map<String, dynamic> json) =>
      CondicionEquipoRequest(Map<String, dynamic>.from(json));

  Map<String, dynamic> toJson() => data;
}

class ControlLlantasRequest {
  final Map<String, dynamic> data;

  ControlLlantasRequest(this.data);

  factory ControlLlantasRequest.fromJson(Map<String, dynamic> json) =>
      ControlLlantasRequest(Map<String, dynamic>.from(json));

  Map<String, dynamic> toJson() => data;
}

class ChecklistRespuestaRequest {
  final int? id;
  final int decision;
  final String observacion;

  ChecklistRespuestaRequest({
    this.id,
    required this.decision,
    this.observacion = '',
  });

  factory ChecklistRespuestaRequest.fromJson(Map<String, dynamic> json) =>
      ChecklistRespuestaRequest(
        id: json['id'] as int?,
        decision: json['decision'] as int? ?? 0,
        observacion: json['observacion'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'decision': decision,
    'observacion': observacion,
  };
}

// --- Registro wrapper (generic over operacion detail type) ---

class RegistroRequest<T> {
  final int? id;
  final int numero;
  final String estado;
  final String codigo;
  final String horaInicio;
  final String horaFinal;
  final T? operacion;

  RegistroRequest({
    this.id,
    required this.numero,
    required this.estado,
    required this.codigo,
    required this.horaInicio,
    this.horaFinal = '',
    this.operacion,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'numero': numero,
    'estado': estado,
    'codigo': codigo,
    'hora_inicio': horaInicio,
    'hora_final': horaFinal,
    if (operacion != null) 'operacion': (operacion as dynamic).toJson(),
  };
}

// --- Registro Operacion Detalle variants ---

class RegistroOperacionTalLargoDetalleRequest {
  final int? nTaladrosProduccion;
  final double? metrosPerforadosProduccion;
  final int? nTaladrosRimados;
  final double? metrosPerforadosRimados;
  final int? nTaladrosAlivio;
  final double? metrosPerforadosAlivio;
  final int? nTaladrosRepaso;
  final double? metrosPerforadosRepaso;
  final double? longBarras;
  final int? numBarras;
  final int? tipoPerforacionId;
  final String? observaciones;
  final int? laborId;
  final String? ala;
  final int? alaId;

  RegistroOperacionTalLargoDetalleRequest({
    this.nTaladrosProduccion,
    this.metrosPerforadosProduccion,
    this.nTaladrosRimados,
    this.metrosPerforadosRimados,
    this.nTaladrosAlivio,
    this.metrosPerforadosAlivio,
    this.nTaladrosRepaso,
    this.metrosPerforadosRepaso,
    this.longBarras,
    this.numBarras,
    this.tipoPerforacionId,
    this.observaciones,
    this.laborId,
    this.ala,
    this.alaId,
  });

  factory RegistroOperacionTalLargoDetalleRequest.fromJson(
    Map<String, dynamic> json,
  ) => RegistroOperacionTalLargoDetalleRequest(
    nTaladrosProduccion: json['n_taladros_produccion'],
    metrosPerforadosProduccion: _toDouble(json['metros_perforados_produccion']),
    nTaladrosRimados: json['n_taladros_rimados'],
    metrosPerforadosRimados: _toDouble(json['metros_perforados_rimados']),
    nTaladrosAlivio: json['n_taladros_alivio'],
    metrosPerforadosAlivio: _toDouble(json['metros_perforados_alivio']),
    nTaladrosRepaso: json['n_taladros_repaso'],
    metrosPerforadosRepaso: _toDouble(json['metros_perforados_repaso']),
    longBarras: _toDouble(json['long_barras']),
    numBarras: json['num_barras'],
    tipoPerforacionId: json['tipo_perforacion_id'],
    observaciones: json['observaciones'],
    laborId: json['labor_id'],
    ala: json['ala'],
    alaId: json['ala_id'],
  );

  Map<String, dynamic> toJson() => {
    if (nTaladrosProduccion != null)
      'n_taladros_produccion': nTaladrosProduccion,
    if (metrosPerforadosProduccion != null)
      'metros_perforados_produccion': metrosPerforadosProduccion,
    if (nTaladrosRimados != null) 'n_taladros_rimados': nTaladrosRimados,
    if (metrosPerforadosRimados != null)
      'metros_perforados_rimados': metrosPerforadosRimados,
    if (nTaladrosAlivio != null) 'n_taladros_alivio': nTaladrosAlivio,
    if (metrosPerforadosAlivio != null)
      'metros_perforados_alivio': metrosPerforadosAlivio,
    if (nTaladrosRepaso != null) 'n_taladros_repaso': nTaladrosRepaso,
    if (metrosPerforadosRepaso != null)
      'metros_perforados_repaso': metrosPerforadosRepaso,
    if (longBarras != null) 'long_barras': longBarras,
    if (numBarras != null) 'num_barras': numBarras,
    if (tipoPerforacionId != null) 'tipo_perforacion_id': tipoPerforacionId,
    if (observaciones != null) 'observaciones': observaciones,
    if (laborId != null) 'labor_id': laborId,
    if (ala != null) 'ala': ala,
    if (alaId != null) 'ala_id': alaId,
  };
}

class RegistroOperacionTalHorizontalDetalleRequest {
  final int? talProd;
  final int? talRimados;
  final int? talAlivio;
  final int? talRepaso;
  final double? longBarras;
  final int? numBarras;
  final int? tipoPerforacionId;
  final String? observaciones;

  RegistroOperacionTalHorizontalDetalleRequest({
    this.talProd,
    this.talRimados,
    this.talAlivio,
    this.talRepaso,
    this.longBarras,
    this.numBarras,
    this.tipoPerforacionId,
    this.observaciones,
  });

  factory RegistroOperacionTalHorizontalDetalleRequest.fromJson(
    Map<String, dynamic> json,
  ) => RegistroOperacionTalHorizontalDetalleRequest(
    talProd: json['tal_prod'],
    talRimados: json['tal_rimados'],
    talAlivio: json['tal_alivio'],
    talRepaso: json['tal_repaso'],
    longBarras: _toDouble(json['long_barras']),
    numBarras: json['num_barras'],
    tipoPerforacionId: json['tipo_perforacion_id'],
    observaciones: json['observaciones'],
  );

  Map<String, dynamic> toJson() => {
    if (talProd != null) 'tal_prod': talProd,
    if (talRimados != null) 'tal_rimados': talRimados,
    if (talAlivio != null) 'tal_alivio': talAlivio,
    if (talRepaso != null) 'tal_repaso': talRepaso,
    if (longBarras != null) 'long_barras': longBarras,
    if (numBarras != null) 'num_barras': numBarras,
    if (tipoPerforacionId != null) 'tipo_perforacion_id': tipoPerforacionId,
    if (observaciones != null) 'observaciones': observaciones,
  };
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

class OperacionEmpernadorRegistroDetalleRequest {
  final String? nivel;
  final String? tipoLabor;
  final String? labor;
  final String? ala;
  final String? tipoPernos;
  final num? logPernos;
  final num? nPernosInstalados;
  final String? tipoMalla;
  final String? mt52Malla;
  final String? sistematicoPuntual;
  final String? observaciones;

  OperacionEmpernadorRegistroDetalleRequest({
    this.nivel,
    this.tipoLabor,
    this.labor,
    this.ala,
    this.tipoPernos,
    this.logPernos,
    this.nPernosInstalados,
    this.tipoMalla,
    this.mt52Malla,
    this.sistematicoPuntual,
    this.observaciones,
  });

  factory OperacionEmpernadorRegistroDetalleRequest.fromJson(
    Map<String, dynamic> json,
  ) => OperacionEmpernadorRegistroDetalleRequest(
    nivel: json['nivel'] as String?,
    tipoLabor: json['tipo_labor'] as String?,
    labor: json['labor'] as String?,
    ala: json['ala'] as String?,
    tipoPernos: json['tipo_pernos'] as String?,
    logPernos: json['log_pernos'] as num?,
    nPernosInstalados: json['n_pernos_instalados'] as num?,
    tipoMalla: json['tipo_malla'] as String?,
    mt52Malla: json['mt52_malla'] as String?,
    sistematicoPuntual: json['sistematico_puntual'] as String?,
    observaciones: json['observaciones'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (nivel != null) 'nivel': nivel,
    if (tipoLabor != null) 'tipo_labor': tipoLabor,
    if (labor != null) 'labor': labor,
    if (ala != null) 'ala': ala,
    if (tipoPernos != null) 'tipo_pernos': tipoPernos,
    if (logPernos != null) 'log_pernos': logPernos,
    if (nPernosInstalados != null) 'n_pernos_instalados': nPernosInstalados,
    if (tipoMalla != null) 'tipo_malla': tipoMalla,
    if (mt52Malla != null) 'mt52_malla': mt52Malla,
    if (sistematicoPuntual != null) 'sistematico_puntual': sistematicoPuntual,
    if (observaciones != null) 'observaciones': observaciones,
  };
}

class OperacionCarguioRegistroDetalleRequest {
  final String? nivelInicio;
  final String? tipoLaborInicio;
  final String? laborInicio;
  final String? alaInicio;
  final String? ubicacionDestino;
  final int? nCucharas;
  final String? observaciones;

  OperacionCarguioRegistroDetalleRequest({
    this.nivelInicio,
    this.tipoLaborInicio,
    this.laborInicio,
    this.alaInicio,
    this.ubicacionDestino,
    this.nCucharas,
    this.observaciones,
  });

  factory OperacionCarguioRegistroDetalleRequest.fromJson(
    Map<String, dynamic> json,
  ) => OperacionCarguioRegistroDetalleRequest(
    nivelInicio: json['nivel_inicio'] as String?,
    tipoLaborInicio: json['tipo_labor_inicio'] as String?,
    laborInicio: json['labor_inicio'] as String?,
    alaInicio: json['ala_inicio'] as String?,
    ubicacionDestino: json['ubicacion_destino'] as String?,
    nCucharas: json['n_cucharas'] as int?,
    observaciones: json['observaciones'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (nivelInicio != null) 'nivel_inicio': nivelInicio,
    if (tipoLaborInicio != null) 'tipo_labor_inicio': tipoLaborInicio,
    if (laborInicio != null) 'labor_inicio': laborInicio,
    if (alaInicio != null) 'ala_inicio': alaInicio,
    if (ubicacionDestino != null) 'ubicacion_destino': ubicacionDestino,
    if (nCucharas != null) 'n_cucharas': nCucharas,
    if (observaciones != null) 'observaciones': observaciones,
  };
}

class OperacionScalaminRegistroDetalleRequest {
  final String? nivel;
  final String? tipoLabor;
  final String? labor;
  final String? ala;
  final String? observaciones;

  OperacionScalaminRegistroDetalleRequest({
    this.nivel,
    this.tipoLabor,
    this.labor,
    this.ala,
    this.observaciones,
  });

  factory OperacionScalaminRegistroDetalleRequest.fromJson(
    Map<String, dynamic> json,
  ) => OperacionScalaminRegistroDetalleRequest(
    nivel: json['nivel'] as String?,
    tipoLabor: json['tipo_labor'] as String?,
    labor: json['labor'] as String?,
    ala: json['ala'] as String?,
    observaciones: json['observaciones'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (nivel != null) 'nivel': nivel,
    if (tipoLabor != null) 'tipo_labor': tipoLabor,
    if (labor != null) 'labor': labor,
    if (ala != null) 'ala': ala,
    if (observaciones != null) 'observaciones': observaciones,
  };
}

class OperacionScissorRegistroDetalleRequest {
  final String? origenNivel;
  final String? origenTipoLabor;
  final String? origenLabor;
  final String? origenAla;
  final String? destinoNivel;
  final String? destinoTipoLabor;
  final String? destinoLabor;
  final String? destinoAla;
  final String? observaciones;

  OperacionScissorRegistroDetalleRequest({
    this.origenNivel,
    this.origenTipoLabor,
    this.origenLabor,
    this.origenAla,
    this.destinoNivel,
    this.destinoTipoLabor,
    this.destinoLabor,
    this.destinoAla,
    this.observaciones,
  });

  factory OperacionScissorRegistroDetalleRequest.fromJson(
    Map<String, dynamic> json,
  ) => OperacionScissorRegistroDetalleRequest(
    origenNivel: json['origen_nivel'] as String?,
    origenTipoLabor: json['origen_tipo_labor'] as String?,
    origenLabor: json['origen_labor'] as String?,
    origenAla: json['origen_ala'] as String?,
    destinoNivel: json['destino_nivel'] as String?,
    destinoTipoLabor: json['destino_tipo_labor'] as String?,
    destinoLabor: json['destino_labor'] as String?,
    destinoAla: json['destino_ala'] as String?,
    observaciones: json['observaciones'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (origenNivel != null) 'origen_nivel': origenNivel,
    if (origenTipoLabor != null) 'origen_tipo_labor': origenTipoLabor,
    if (origenLabor != null) 'origen_labor': origenLabor,
    if (origenAla != null) 'origen_ala': origenAla,
    if (destinoNivel != null) 'destino_nivel': destinoNivel,
    if (destinoTipoLabor != null) 'destino_tipo_labor': destinoTipoLabor,
    if (destinoLabor != null) 'destino_labor': destinoLabor,
    if (destinoAla != null) 'destino_ala': destinoAla,
    if (observaciones != null) 'observaciones': observaciones,
  };
}

// --- Base Upsert Request (shared fields) ---

class OperacionUpsertRequest {
  final String? fecha;
  final int? turnoId;
  final int? laborId;
  final int? operadorId;
  final int? jefeGuardiaId;
  final int? equipoId;
  final String? estado;
  final int? envio;
  final int? revisado;
  final int? aprobacion;
  final HorometrosRequest? horometros;
  final CondicionEquipoRequest? condicionesEquipo;
  final List<ChecklistRespuestaRequest>? checkList;
  final ControlLlantasRequest? controlLlantas;
  final dynamic observacionesJefe;
  final dynamic observacionesJefe2;
  final dynamic observacionesJefe3;

  OperacionUpsertRequest({
    this.fecha,
    this.turnoId,
    this.laborId,
    this.operadorId,
    this.jefeGuardiaId,
    this.equipoId,
    this.estado,
    this.envio,
    this.revisado,
    this.aprobacion,
    this.horometros,
    this.condicionesEquipo,
    this.checkList,
    this.controlLlantas,
    this.observacionesJefe,
    this.observacionesJefe2,
    this.observacionesJefe3,
  });

  Map<String, dynamic> toJson() => {
    if (fecha != null) 'fecha': fecha,
    if (turnoId != null) 'turno_id': turnoId,
    if (laborId != null) 'labor_id': laborId,
    if (operadorId != null) 'operador_id': operadorId,
    if (jefeGuardiaId != null) 'jefe_guardia_id': jefeGuardiaId,
    if (equipoId != null) 'equipo_id': equipoId,
    if (estado != null) 'estado': estado,
    if (envio != null) 'envio': envio,
    if (revisado != null) 'revisado': revisado,
    if (aprobacion != null) 'aprobacion': aprobacion,
    if (horometros != null) 'horometros': horometros!.toJson(),
    if (condicionesEquipo != null)
      'condiciones_equipo': condicionesEquipo!.toJson(),
    if (checkList != null)
      'check_list': checkList!.map((e) => e.toJson()).toList(),
    if (controlLlantas != null) 'control_llantas': controlLlantas!.toJson(),
    if (observacionesJefe != null) 'observaciones_jefe': observacionesJefe,
    if (observacionesJefe2 != null) 'observaciones_jefe2': observacionesJefe2,
    if (observacionesJefe3 != null) 'observaciones_jefe3': observacionesJefe3,
  };
}

// --- Typed Upsert Requests ---

class OperacionTalLargoUpsertRequest extends OperacionUpsertRequest {
  final List<RegistroRequest<RegistroOperacionTalLargoDetalleRequest>>?
  registros;

  OperacionTalLargoUpsertRequest({
    super.fecha,
    super.turnoId,
    super.laborId,
    super.operadorId,
    super.jefeGuardiaId,
    super.equipoId,
    super.estado,
    super.envio,
    super.revisado,
    super.aprobacion,
    super.horometros,
    super.condicionesEquipo,
    super.checkList,
    super.controlLlantas,
    super.observacionesJefe,
    super.observacionesJefe2,
    super.observacionesJefe3,
    this.registros,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (registros != null)
      'registros': registros!.map((r) => r.toJson()).toList(),
  };
}

class OperacionTalHorizontalUpsertRequest extends OperacionUpsertRequest {
  final List<RegistroRequest<RegistroOperacionTalHorizontalDetalleRequest>>?
  registros;

  OperacionTalHorizontalUpsertRequest({
    super.fecha,
    super.turnoId,
    super.laborId,
    super.operadorId,
    super.jefeGuardiaId,
    super.equipoId,
    super.estado,
    super.envio,
    super.revisado,
    super.aprobacion,
    super.horometros,
    super.condicionesEquipo,
    super.checkList,
    super.controlLlantas,
    super.observacionesJefe,
    super.observacionesJefe2,
    super.observacionesJefe3,
    this.registros,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (registros != null)
      'registros': registros!.map((r) => r.toJson()).toList(),
  };
}

class OperacionCarguioUpsertRequest extends OperacionUpsertRequest {
  final List<RegistroRequest<OperacionCarguioRegistroDetalleRequest>>?
  registros;

  OperacionCarguioUpsertRequest({
    super.fecha,
    super.turnoId,
    super.laborId,
    super.operadorId,
    super.jefeGuardiaId,
    super.equipoId,
    super.estado,
    super.envio,
    super.revisado,
    super.aprobacion,
    super.horometros,
    super.condicionesEquipo,
    super.checkList,
    super.controlLlantas,
    super.observacionesJefe,
    super.observacionesJefe2,
    super.observacionesJefe3,
    this.registros,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (registros != null)
      'registros': registros!.map((r) => r.toJson()).toList(),
  };
}

class OperacionEmpernadorUpsertRequest extends OperacionUpsertRequest {
  final List<RegistroRequest<OperacionEmpernadorRegistroDetalleRequest>>?
  registros;

  OperacionEmpernadorUpsertRequest({
    super.fecha,
    super.turnoId,
    super.laborId,
    super.operadorId,
    super.jefeGuardiaId,
    super.equipoId,
    super.estado,
    super.envio,
    super.revisado,
    super.aprobacion,
    super.horometros,
    super.condicionesEquipo,
    super.checkList,
    super.controlLlantas,
    super.observacionesJefe,
    super.observacionesJefe2,
    super.observacionesJefe3,
    this.registros,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (registros != null)
      'registros': registros!.map((r) => r.toJson()).toList(),
  };
}

class OperacionScalaminUpsertRequest extends OperacionUpsertRequest {
  final List<RegistroRequest<OperacionScalaminRegistroDetalleRequest>>?
  registros;

  OperacionScalaminUpsertRequest({
    super.fecha,
    super.turnoId,
    super.laborId,
    super.operadorId,
    super.jefeGuardiaId,
    super.equipoId,
    super.estado,
    super.envio,
    super.revisado,
    super.aprobacion,
    super.horometros,
    super.condicionesEquipo,
    super.checkList,
    super.controlLlantas,
    super.observacionesJefe,
    super.observacionesJefe2,
    super.observacionesJefe3,
    this.registros,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (registros != null)
      'registros': registros!.map((r) => r.toJson()).toList(),
  };
}

class OperacionScissorUpsertRequest extends OperacionUpsertRequest {
  final List<RegistroRequest<OperacionScissorRegistroDetalleRequest>>?
  registros;

  OperacionScissorUpsertRequest({
    super.fecha,
    super.turnoId,
    super.laborId,
    super.operadorId,
    super.jefeGuardiaId,
    super.equipoId,
    super.estado,
    super.envio,
    super.revisado,
    super.aprobacion,
    super.horometros,
    super.condicionesEquipo,
    super.checkList,
    super.controlLlantas,
    super.observacionesJefe,
    super.observacionesJefe2,
    super.observacionesJefe3,
    this.registros,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (registros != null)
      'registros': registros!.map((r) => r.toJson()).toList(),
  };
}
