class OperacionCardConfig {
  final String proceso;
  final bool mostrarModelo;
  final bool mostrarCapacidad;
  final bool mostrarTipoEquipo;
  final bool usarAutorizacion;
  final bool soloIds;
  final String claveCodigo;
  final String claveJefeGuardia;

  const OperacionCardConfig({
    required this.proceso,
    this.mostrarModelo = false,
    this.mostrarCapacidad = false,
    this.mostrarTipoEquipo = false,
    this.usarAutorizacion = false,
    this.soloIds = false,
    this.claveCodigo = 'codigo',
    this.claveJefeGuardia = 'jefeGuardia',
  });
}
