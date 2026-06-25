import 'package:flutter/material.dart';
import 'package:i_miner/screens/Operaciones/lista_perforacion_screen.dart';
import 'package:i_miner/screens/widgets/dialogo_confirmar_cierre.dart';
import 'package:i_miner/screens/widgets/botones_estado.dart';
import 'package:i_miner/screens/widgets/tabla_operaciones.dart';
import 'package:i_miner/screens/widgets/show_registro_operacion.dart';
import 'package:i_miner/screens/widgets/dialogo_condiciones_equipo.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/screens/widgets/dialogo_formulario_no_operativo.dart';
import 'package:i_miner/screens/widgets/botones_acciones_inferiores.dart';
import 'package:i_miner/screens/widgets/dialog_check_imagen.dart';

// Carguio Scoop widgets
import 'package:i_miner/screens/Operaciones/Carguio/Scoop/widgets/dialogo_formulario_perforacion.dart'
    as cs;

// Carguio Dumper widgets
import 'package:i_miner/screens/Operaciones/Carguio/Dumper/widgets/dialogo_formulario_perforacion.dart'
    as cd;

import 'package:i_miner/shared/widgets/registro_operacion_dialog.dart';

class CarguioScreen extends StatelessWidget {
  final String? rolUsuario;
  final String? dniUsuario;

  const CarguioScreen({Key? key, this.rolUsuario, this.dniUsuario})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1B5E6B);
    final Color accentColor = const Color(0xFF1B5E6B);

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,

        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 16,
              ), // 🔥 icono acorde a carguío
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'CARGUÍO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500, // 🔥 más elegante que w600
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Diseño responsivo
                final isLargeScreen = constraints.maxWidth > 800;
                final itemWidth = isLargeScreen
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtítulo corporativo
                    Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.construction_rounded,
                            size: 48,
                            color: accentColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Seleccione el equipo para gestionar sus operaciones',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Container(width: 60, height: 2, color: accentColor),
                        ],
                      ),
                    ),

                    // Grid de botones corporativos
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: CorporateButton(
                            title: 'DUMPER',
                            subtitle: 'Equipo de transporte',
                            icon: Icons.local_shipping_rounded,
                            backgroundColor: primaryColor,
                            accentColor: accentColor,
                            onPressed: () {
                              // 🔥 Mensaje temporal
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'DUMPER aún no está disponible',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              // 🔥 Navegación comentada por ahora
                              /*
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OperacionListScreen(
        rolUsuario: rolUsuario,
        dniUsuario: dniUsuario,
        config: const OperacionScreenConfig(proceso: 'CARGUÍO', procesoId: 6, dbSuffix: 'Dumper', operacionNombreDb: 'Dumper', hasChecklistTelemando: true, hasProgramaTrabajo: true),
        onShowDialogoRegistro: (context, turno, estado, procesoId, categoriaId, ultimaHora, existingRecord) => showRegistroOperacionDialog(context: context, dialog: RegistroOperacionDialog(turno: turno, selectedState: estado, procesoId: procesoId, categoriaId: categoriaId, ultimaHoraRegistrada: ultimaHora, existingRecord: existingRecord?.map((k, v) => MapEntry(k, v.toString())), onConfirm: (data) => Navigator.of(context).pop(data))),
        onBuildDialogoPerforacion: (context, operacionId, estadoId, datosIniciales, fecha, turno, primaryColor, onGuardar) => cd.DialogoFormularioPerforacion(operacionId: operacionId, estadoId: estadoId, datosIniciales: datosIniciales, estado: "OPERATIVO", fecha: fecha, turno: turno, primaryColor: primaryColor, onGuardar: onGuardar),
        onBuildDialogoNoOperativo: (context, operacionId, estadoId, estado, primaryColor, onGuardar, datosIniciales) => DialogoFormularioNoOperativo(operacionId: operacionId, estadoId: estadoId, estado: estado, datosIniciales: datosIniciales, primaryColor: primaryColor, onGuardar: onGuardar),
        onBuildConfirmarCierre: (primaryColor, onConfirmar) => DialogoConfirmarCierreRegistros(primaryColor: primaryColor, onConfirmar: onConfirmar),
        onBuildCondicionesEquipo: (operacionId, estado, condicionesData, primaryColor) => DialogoCondicionesEquipo(operacionId: operacionId, estado: estado, condicionesData: condicionesData, primaryColor: primaryColor, onGuardar: (id, datos) => DatabaseHelper().updateCondicionesEquipoDumper(id, datos)),
        onBuildCheckImagen: (operacionId, estado, controlLlantasData, primaryColor) => DialogoCheckImagen(operacionId: operacionId, estado: estado, controlLlantasData: controlLlantasData ?? {}, primaryColor: primaryColor, onSave: (id, datos) => DatabaseHelper().updateControlLlantasDumper(id, datos)),
        buildBotonesEstado: (onEstadoSeleccionado) => BotonesEstado(onEstadoSeleccionado: onEstadoSeleccionado),
        buildTablaOperaciones: (operaciones, onVerDetalle, onEditar, onEliminar, primaryColor) => TablaOperaciones(operaciones: operaciones, onVerDetalle: onVerDetalle, onEditar: onEditar, onEliminar: onEliminar, primaryColor: primaryColor),
        buildBotonesAcciones: ({required onChecklistPressed, required onHorometroPressed, required onCerrarRegistrosPressed, required onCondicionesEquipoPressed, required onPresionLlantasPressed, required primaryColor, onChecklistTelemandoPressed, onProgramaTrabajoPressed}) => BotonesAccionesInferiores(onChecklistPressed: onChecklistPressed, onHorometroPressed: onHorometroPressed, onCerrarRegistrosPressed: onCerrarRegistrosPressed, onCondicionesEquipoPressed: onCondicionesEquipoPressed, onPresionLlantasPressed: onPresionLlantasPressed, onChecklistTelemandoPressed: onChecklistTelemandoPressed, onProgramaTrabajoPressed: onProgramaTrabajoPressed, primaryColor: primaryColor),
        onChecklistTelemando: (operacionId, estado, primaryColor, context) => showDialog(context: context, builder: (_) => cd.DialogoChecklistTelemando(operacionId: operacionId, estado: estado, primaryColor: primaryColor)),
        onProgramaTrabajo: (operacionId, estado, primaryColor, context) => showDialog(context: context, builder: (_) => cd.DialogoProgramaTrabajo(operacionId: operacionId, estado: estado, primaryColor: primaryColor)),
      ),
    ),
  );
  */
                            },
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: CorporateButton(
                            title: 'SCOOP',
                            subtitle: 'Equipo de carga',
                            icon: Icons.construction_rounded,
                            backgroundColor: primaryColor,
                            accentColor: accentColor,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OperacionListScreen(
                                    rolUsuario: rolUsuario,
                                    dniUsuario: dniUsuario,
                                    config: const OperacionScreenConfig(
                                      proceso: 'SCOOP',
                                      procesoId: 4,
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
                                              (k, v) =>
                                                  MapEntry(k, v.toString()),
                                            ),
                                            onConfirm: (data) =>
                                                Navigator.of(context).pop(data),
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
                                    onBuildConfirmarCierre:
                                        (primaryColor, onConfirmar) =>
                                            DialogoConfirmarCierreRegistros(
                                              primaryColor: primaryColor,
                                              onConfirmar: onConfirmar,
                                            ),
                                    onBuildCondicionesEquipo:
                                        (
                                          operacionId,
                                          estado,
                                          condicionesData,
                                          primaryColor,
                                        ) => DialogoCondicionesEquipo(
                                          operacionId: operacionId,
                                          estado: estado,
                                          condicionesData: condicionesData,
                                          primaryColor: primaryColor,
                                          onGuardar: (id, datos) =>
                                              DatabaseHelper()
                                                  .updateCondicionesEquipoCarguio(
                                                    id,
                                                    datos,
                                                  ),
                                        ),
                                    onBuildCheckImagen:
                                        (
                                          operacionId,
                                          estado,
                                          controlLlantasData,
                                          primaryColor,
                                        ) => DialogoCheckImagen(
                                          operacionId: operacionId,
                                          estado: estado,
                                          controlLlantasData:
                                              controlLlantasData ?? {},
                                          primaryColor: primaryColor,
                                          onSave: (id, datos) => DatabaseHelper().updateControlLlantasCarguio(id, datos),
                                        ),
                                    buildBotonesEstado:
                                        (onEstadoSeleccionado) => BotonesEstado(
                                          onEstadoSeleccionado:
                                              onEstadoSeleccionado,
                                        ),
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
                                          onChecklistPressed:
                                              onChecklistPressed,
                                          onHorometroPressed:
                                              onHorometroPressed,
                                          onCerrarRegistrosPressed:
                                              onCerrarRegistrosPressed,
                                          onCondicionesEquipoPressed:
                                              onCondicionesEquipoPressed,
                                          onPresionLlantasPressed:
                                              onPresionLlantasPressed,
                                          primaryColor: primaryColor,
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Footer informativo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Seleccione el equipo para registrar operaciones',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Reutilizamos el mismo CorporateButton de ServiciosAuxiliares
class CorporateButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
  final VoidCallback onPressed;

  const CorporateButton({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: accentColor),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: backgroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 2,
                color: accentColor.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Gestionar',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: accentColor),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
