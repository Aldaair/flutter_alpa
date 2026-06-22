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
// Taladro Largo + Taladro Horizontal share the same detalle shape.

class RegistroOperacionTalDetalleRequest {
  final String? nivel;
  final String? tipoLabor;
  final String? labor;
  final String? ala;
  final String? talProd;
  final String? talRimados;
  final String? talAlivio;
  final String? talRepaso;
  final String? longBarras;
  final String? numBarras;
  final String? tipoPerforacion;
  final int? tipoPerforacionId;
  final String? observaciones;

  RegistroOperacionTalDetalleRequest({
    this.nivel,
    this.tipoLabor,
    this.labor,
    this.ala,
    this.talProd,
    this.talRimados,
    this.talAlivio,
    this.talRepaso,
    this.longBarras,
    this.numBarras,
    this.tipoPerforacion,
    this.tipoPerforacionId,
    this.observaciones,
  });

  Map<String, dynamic> toJson() => {
        if (nivel != null) 'nivel': nivel,
        if (tipoLabor != null) 'tipo_labor': tipoLabor,
        if (labor != null) 'labor': labor,
        if (ala != null) 'ala': ala,
        if (talProd != null) 'tal_prod': talProd,
        if (talRimados != null) 'tal_rimados': talRimados,
        if (talAlivio != null) 'tal_alivio': talAlivio,
        if (talRepaso != null) 'tal_repaso': talRepaso,
        if (longBarras != null) 'long_barras': longBarras,
        if (numBarras != null) 'num_barras': numBarras,
        if (tipoPerforacion != null) 'tipo_perforacion': tipoPerforacion,
        if (tipoPerforacionId != null) 'tipo_perforacion_id': tipoPerforacionId,
        if (observaciones != null) 'observaciones': observaciones,
      };
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
        if (observacionesJefe2 != null)
          'observaciones_jefe2': observacionesJefe2,
        if (observacionesJefe3 != null)
          'observaciones_jefe3': observacionesJefe3,
      };
}

// --- Typed Upsert Requests ---

class OperacionTalLargoUpsertRequest extends OperacionUpsertRequest {
  final List<RegistroRequest<RegistroOperacionTalDetalleRequest>>? registros;

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
  final List<RegistroRequest<RegistroOperacionTalDetalleRequest>>? registros;

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
  final List<RegistroRequest<OperacionCarguioRegistroDetalleRequest>>? registros;

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


