Map<String, dynamic> buildCommonOperationHeader(
  Map<String, dynamic> operacion,
) {
  return {
    'turno_id': operacion['turno_id'],
    'frente_origen': operacion['frente_origen'],
    'registrador_usuario_id': operacion['registrador_usuario_id'],
    'registrador_nombre': operacion['registrador_nombre'],
    'equipo_id': operacion['equipo_id'],
    'jefe_guardia_id': operacion['jefe_guardia_id'],
    'labor_id': operacion['labor_id'],
  };
}

List<Map<String, dynamic>> sanitizeRegistrosForExport(
  List<Map<String, dynamic>> registros,
) {
  const keysToRemove = {
    'frente_origen',
    'labor_id',
    'mina',
    'zona',
    'area',
    'fase',
    'estructura_mineral',
    'tipo_labor',
    'labor',
    'ala',
    'nivel',
  };

  return registros.map((registro) {
    final copy = Map<String, dynamic>.from(registro);
    final operacion = copy['operacion'];
    if (operacion is Map) {
      final operacionCopy = Map<String, dynamic>.from(operacion);
      for (final key in keysToRemove) {
        operacionCopy.remove(key);
      }
      copy['operacion'] = operacionCopy;
    }
    return copy;
  }).toList();
}
