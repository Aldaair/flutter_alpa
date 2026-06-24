import 'package:flutter/material.dart';

class OperatorSelectorCard extends StatelessWidget {
  const OperatorSelectorCard({
    super.key,
    required this.operators,
    required this.selectedOperatorId,
    required this.onChanged,
    this.primaryColor = const Color(0xFF1B5E6B),
  });

  final List<Map<String, dynamic>> operators;
  final int? selectedOperatorId;
  final ValueChanged<int?> onChanged;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operador visible',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _containsSelected() ? selectedOperatorId : null,
              decoration: const InputDecoration(
                labelText: 'Seleccionar operador',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: operators.map((operator) {
                final operatorId = operator['id'] as int?;
                final dni = operator['codigo_dni']?.toString() ?? '';
                final nombres = operator['nombres']?.toString() ?? '';
                final apellidos = operator['apellidos']?.toString() ?? '';
                final label = '$apellidos $nombres'.trim();

                return DropdownMenuItem<int>(
                  value: operatorId,
                  child: Text(
                    dni.isEmpty ? label : '$label - $dni',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: operators.isEmpty ? null : onChanged,
              hint: Text(
                operators.isEmpty
                    ? 'Aun no hay operadores conocidos en este dispositivo'
                    : 'Seleccionar operador',
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _containsSelected() {
    return operators.any((operator) => operator['id'] == selectedOperatorId);
  }
}
