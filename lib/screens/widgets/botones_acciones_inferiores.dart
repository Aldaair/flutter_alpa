import 'package:flutter/material.dart';

class BotonesAccionesInferiores extends StatelessWidget {
  final VoidCallback onChecklistPressed;
  final VoidCallback onHorometroPressed;
  final VoidCallback onCerrarRegistrosPressed;
  final VoidCallback onCondicionesEquipoPressed;
  final VoidCallback onPresionLlantasPressed;
  final Color primaryColor;
  final VoidCallback? onChecklistTelemandoPressed;
  final VoidCallback? onProgramaTrabajoPressed;
  final bool isCerrado;

  const BotonesAccionesInferiores({
    super.key,
    required this.onChecklistPressed,
    required this.onHorometroPressed,
    required this.onCerrarRegistrosPressed,
    required this.onCondicionesEquipoPressed,
    required this.onPresionLlantasPressed,
    required this.primaryColor,
    this.onChecklistTelemandoPressed,
    this.onProgramaTrabajoPressed,
    this.isCerrado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAccionBoton(
                  icon: Icons.speed,
                  label: 'Horómetro',
                  onPressed: onHorometroPressed,
                ),
                _buildAccionBoton(
                  icon: Icons.build,
                  label: 'Condiciones de equipo',
                  onPressed: onCondicionesEquipoPressed,
                ),
                _buildAccionBoton(
                  icon: Icons.checklist,
                  label: 'CheckList',
                  onPressed: onChecklistPressed,
                ),
                _buildAccionBoton(
                  icon: Icons.tire_repair,
                  label: 'Presión de llantas',
                  onPressed: onPresionLlantasPressed,
                ),
                _buildAccionBoton(
                  icon: Icons.lock_outline,
                  label: 'Cerrar registro',
                  onPressed: onCerrarRegistrosPressed,
                  enabled: !isCerrado,
                ),
                if (onProgramaTrabajoPressed != null)
                  _buildAccionBoton(
                    icon: Icons.work,
                    label: 'Programa de trabajo',
                    onPressed: onProgramaTrabajoPressed!,
                  ),
                if (onChecklistTelemandoPressed != null)
                  _buildAccionBoton(
                    icon: Icons.checklist,
                    label: 'CheckList Telemando',
                    onPressed: onChecklistTelemandoPressed!,
                  ),
              ],
            );
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAccionBoton(
                    icon: Icons.checklist,
                    label: 'CheckList',
                    onPressed: onChecklistPressed,
                  ),
                  const SizedBox(width: 8),
                  _buildAccionBoton(
                    icon: Icons.speed,
                    label: 'Horómetro',
                    onPressed: onHorometroPressed,
                  ),
                  const SizedBox(width: 8),
                  _buildAccionBoton(
                    icon: Icons.lock_outline,
                    label: 'Cerrar',
                    onPressed: onCerrarRegistrosPressed,
                    enabled: !isCerrado,
                  ),
                  const SizedBox(width: 8),
                  _buildAccionBoton(
                    icon: Icons.build,
                    label: 'Condiciones',
                    onPressed: onCondicionesEquipoPressed,
                  ),
                  const SizedBox(width: 8),
                  _buildAccionBoton(
                    icon: Icons.tire_repair,
                    label: 'Presión',
                    onPressed: onPresionLlantasPressed,
                  ),
                  if (onProgramaTrabajoPressed != null) ...[
                    const SizedBox(width: 8),
                    _buildAccionBoton(
                      icon: Icons.work,
                      label: 'Programa trabajo',
                      onPressed: onProgramaTrabajoPressed!,
                    ),
                  ],
                  if (onChecklistTelemandoPressed != null) ...[
                    const SizedBox(width: 8),
                    _buildAccionBoton(
                      icon: Icons.checklist,
                      label: 'CheckList Telemando',
                      onPressed: onChecklistTelemandoPressed!,
                    ),
                  ],
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildAccionBoton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    final color = enabled ? primaryColor : Colors.grey;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
