String? resolveAcarreoTipoEquipoFromName(String? equipoNombre) {
  final normalized = equipoNombre?.trim().toUpperCase() ?? '';
  if (normalized.contains('LOCOMOTORA')) {
    return 'LOCOMOTORA';
  }
  if (normalized.contains('VOLQUETE')) {
    return 'VOLQUETE';
  }
  return null;
}

String? resolveAcarreoTipoEquipoFromOperation(
  Map<String, dynamic>? operacionContext,
) {
  final tipoEquipo = _normalizeAcarreoTipoEquipo(
    operacionContext?['tipo_equipo']?.toString() ??
        operacionContext?['tipoEquipo']?.toString(),
  );
  if (tipoEquipo != null) {
    return tipoEquipo;
  }

  final equipoNombre =
      operacionContext?['equipo']?.toString() ??
      operacionContext?['equipo_nombre']?.toString() ??
      operacionContext?['nombre_equipo']?.toString();

  return resolveAcarreoTipoEquipoFromName(equipoNombre);
}

bool isAcarreoLocomotoraOperation(Map<String, dynamic>? operacionContext) {
  return resolveAcarreoTipoEquipoFromOperation(operacionContext) ==
      'LOCOMOTORA';
}

String? _normalizeAcarreoTipoEquipo(String? tipoEquipo) {
  final normalized = tipoEquipo?.trim().toUpperCase() ?? '';
  if (normalized.contains('LOCOMOTORA')) {
    return 'LOCOMOTORA';
  }
  if (normalized.contains('VOLQUETE')) {
    return 'VOLQUETE';
  }
  return null;
}
