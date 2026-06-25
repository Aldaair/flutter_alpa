import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';

class BotonesEstado extends StatefulWidget {
  final Function(String, int) onEstadoSeleccionado;

  const BotonesEstado({super.key, required this.onEstadoSeleccionado});

  @override
  State<BotonesEstado> createState() => _BotonesEstadoState();
}

class _BotonesEstadoState extends State<BotonesEstado> {
  List<Map<String, dynamic>> _categorias = [];
  bool _loading = true;

  static const _coloresPorNombre = <String, Color>{
    'OPERATIVO': Color(0xFF4CAF50),
    'DEMORA': Color(0xFFFFEB3B),
    'MANTENIMIENTO': Color(0xFF2196F3),
    'FUERA DE PLAN': Color(0xFF9C27B0),
    'RESERVA': Color(0xFFF44336),
  };

  static const _iconosPorNombre = <String, IconData>{
    'OPERATIVO': Icons.check_circle_outline,
    'DEMORA': Icons.access_time,
    'MANTENIMIENTO': Icons.build,
    'FUERA DE PLAN': Icons.warning_amber_rounded,
    'RESERVA': Icons.event_available,
  };

  static const _ordenDeseado = [
    'OPERATIVO',
    'DEMORA',
    'MANTENIMIENTO',
    'FUERA DE PLAN',
    'RESERVA',
  ];

  static const _colorDefault = Color(0xFF607D8B);
  static const _iconDefault = Icons.help_outline;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final categorias = await DatabaseHelper().getCategoriasEstados();
    if (!mounted) return;
    setState(() {
      _categorias = categorias;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          final ordenadas = List<Map<String, dynamic>>.from(_categorias)
            ..sort((a, b) {
              final na = (a['nombre']?.toString() ?? '').toUpperCase();
              final nb = (b['nombre']?.toString() ?? '').toUpperCase();
              final ia = _ordenDeseado.indexOf(na);
              final ib = _ordenDeseado.indexOf(nb);
              final posA = ia >= 0 ? ia : _ordenDeseado.length;
              final posB = ib >= 0 ? ib : _ordenDeseado.length;
              return posA.compareTo(posB);
            });

          final buttons = ordenadas.map((cat) {
            final nombre = (cat['nombre']?.toString() ?? '').toUpperCase();
            final catId = cat['id'] as int;
            final color = _coloresPorNombre[nombre] ?? _colorDefault;
            final icon = _iconosPorNombre[nombre] ?? _iconDefault;
            return _buildEstadoButton(nombre, catId, color, icon);
          }).toList();

          if (isSmallScreen) {
            final rows = <Widget>[];
            for (var i = 0; i < buttons.length; i += 2) {
              final rowChildren = <Widget>[
                Expanded(child: buttons[i]),
              ];
              if (i + 1 < buttons.length) {
                rowChildren.addAll([
                  const SizedBox(width: 8),
                  Expanded(child: buttons[i + 1]),
                ]);
              } else {
                rowChildren.add(const SizedBox(width: 8));
                rowChildren.add(Expanded(child: Container()));
              }
              rows.add(Row(children: rowChildren));
              if (i + 2 < buttons.length) {
                rows.add(const SizedBox(height: 8));
              }
            }
            return Column(children: rows);
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    buttons[i],
                  ],
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEstadoButton(
    String estado,
    int categoriaId,
    Color color,
    IconData icon,
  ) {
    return ElevatedButton(
      onPressed: () => widget.onEstadoSeleccionado(estado, categoriaId),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              estado.toUpperCase(),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
