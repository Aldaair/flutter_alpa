import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/Equipo.dart';
import 'package:i_miner/screens/widgets/custom_dropdown.dart';
import 'package:i_miner/screens/widgets/custom_field.dart';

class OperacionCard extends StatefulWidget {
  final Function(Map<String, dynamic>) onOperacionCreada;
  final Function(String?) onTurnoChanged;
  final Function(String) onFechaChanged;
  final String? dniUsuario;
  final Map<String, dynamic>? operacionExistente;

  final String fechaActual;
  final String? selectedTurno;

  final Color primaryColor;

  const OperacionCard({
    Key? key,
    required this.onOperacionCreada,
    required this.onTurnoChanged,
    required this.onFechaChanged,
    required this.fechaActual,
    required this.selectedTurno,
    required this.operacionExistente,
    this.dniUsuario,
    this.primaryColor = const Color(0xFF1B5E6B),
  }) : super(key: key);

  @override
  State<OperacionCard> createState() => _OperacionCardState();
}

class _OperacionCardState extends State<OperacionCard> {

  String? selectedEquipo;
String? selectedCodigo;
String? selectedModelo;
  String? selectedJefeGuardia;
  String? selectedSeccion;
  String? operador;
  
  bool get operacionBloqueada => widget.operacionExistente != null;

  final String operadorEjemplo = "Juan Pérez";

  List<String> turnos = ['DÍA', 'NOCHE'];

  // ❌ CAMBIADO: ya no son final para poder modificarlas
  List<String> equipos = [];
  List<String> jefesGuardia = [];

  List<String> secciones = [];

  // ✅ NUEVO: Mapa para almacenar los modelos por equipo
  final Map<String, List<String>> codigosPorEquipo = {};
final Map<String, List<String>> modelosPorCodigo = {};
  
  // ✅ NUEVO: Almacenar la lista completa de equipos para acceso rápido
  List<Equipo> equiposCompletos = [];
List<String> codigosFiltrados = [];
List<String> modelosFiltrados = [];

  @override
  void initState() {
    super.initState();
    
    // Cargar datos desde la BD
    _cargarOperadorPorDni();
    _cargarEquipos();
    _cargarJefesGuardia();
    _cargarSecciones();

    if (widget.operacionExistente != null) {
  selectedEquipo = widget.operacionExistente!['equipo'];
  selectedCodigo = widget.operacionExistente!['n_equipo'];
  selectedModelo = widget.operacionExistente!['modelo_equipo'];
  selectedJefeGuardia = widget.operacionExistente!['jefe_guardia'];
  selectedSeccion = widget.operacionExistente!['seccion'];

  codigosFiltrados = codigosPorEquipo[selectedEquipo] ?? [];
  _actualizarModelosPorCodigo(selectedCodigo);
}
  }

  Future<void> _cargarSecciones() async {
  try {
    final dbHelper = DatabaseHelper();

    String tipoOperacion = 'PERFORACIÓN HORIZONTAL';

    final seccionesDB =
        await dbHelper.getSeccionesByProceso(tipoOperacion);

    setState(() {
      secciones = seccionesDB.map((s) => s.nombre).toList()..sort();
    });

    print("Secciones cargadas: $secciones");

  } catch (e) {
    print("Error cargando secciones: $e");
    setState(() {
      secciones = [];
    });
  }
}

  Future<void> _cargarOperadorPorDni() async {
    if (widget.dniUsuario == null) return;

    try {
      final dbHelper = DatabaseHelper();
      final usuario = await dbHelper.getUserByDni(widget.dniUsuario!);

      if (usuario != null) {
        setState(() {
          operador = '${usuario['nombres']} ${usuario['apellidos']}';
        });
        print('Operador cargado: $operador');
      } else {
        print('No se encontró usuario con DNI: ${widget.dniUsuario}');
        setState(() {
          operador = operadorEjemplo; // fallback
        });
      }
    } catch (e) {
      print('Error al cargar operador: $e');
      setState(() {
        operador = operadorEjemplo; // fallback
      });
    }
  }

  // ✅ MEJORADO: Cargar equipos y construir mapa de modelos
Future<void> _cargarEquipos() async {
  try {
    codigosPorEquipo.clear();
    modelosPorCodigo.clear();

    final dbHelper = DatabaseHelper();
    equiposCompletos = await dbHelper.getEquipos();

    String tipoOperacion = 'PERFORACIÓN HORIZONTAL';

    List<Equipo> equiposFiltrados = equiposCompletos
        .where((e) => e.proceso == tipoOperacion)
        .toList();

    Set<String> nombresEquipos = {};

    for (var equipo in equiposFiltrados) {
      nombresEquipos.add(equipo.nombre);

      // equipo -> codigos
      codigosPorEquipo.putIfAbsent(equipo.nombre, () => []);
      if (!codigosPorEquipo[equipo.nombre]!.contains(equipo.codigo)) {
        codigosPorEquipo[equipo.nombre]!.add(equipo.codigo);
      }

      // codigo -> modelos
      modelosPorCodigo.putIfAbsent(equipo.codigo, () => []);
      if (!modelosPorCodigo[equipo.codigo]!.contains(equipo.modelo)) {
        modelosPorCodigo[equipo.codigo]!.add(equipo.modelo);
      }
    }

    setState(() {
  equipos = nombresEquipos.toList()..sort();

  if (selectedEquipo != null) {
    codigosFiltrados = codigosPorEquipo[selectedEquipo] ?? [];
  }

  if (selectedCodigo != null) {
    modelosFiltrados = modelosPorCodigo[selectedCodigo] ?? [];
  }
});

  } catch (e) {
    print("Error cargando equipos: $e");
  }
}

  // ✅ MEJORADO: Cargar jefes de guardia
Future<void> _cargarJefesGuardia() async {
  try {
    final dbHelper = DatabaseHelper();

    List<String> jefesList = await dbHelper.getJefesGuardiaNombres();

    print("Jefes de guardia obtenidos de la BD local: $jefesList");

    setState(() {
      jefesGuardia = jefesList..sort();
    });

    print('Jefes de guardia cargados: $jefesGuardia');

  } catch (e) {
    print("Error al obtener los jefes de guardia: $e");
    setState(() {
      jefesGuardia = [];
    });
  }
}

  @override
  void didUpdateWidget(covariant OperacionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.operacionExistente != oldWidget.operacionExistente) {
      if (widget.operacionExistente != null) {
selectedEquipo = widget.operacionExistente!['equipo'];
selectedCodigo = widget.operacionExistente!['n_equipo'];
selectedModelo = widget.operacionExistente!['modelo_equipo'];

codigosFiltrados = codigosPorEquipo[selectedEquipo] ?? [];
_actualizarModelosPorCodigo(selectedCodigo);

selectedJefeGuardia = widget.operacionExistente!['jefe_guardia'];
selectedSeccion = widget.operacionExistente!['seccion'];
      } else {
        selectedEquipo = null;
selectedCodigo = null;
selectedModelo = null;
selectedJefeGuardia = null;
selectedSeccion = null;
codigosFiltrados = [];
modelosFiltrados = [];
      }
      setState(() {});
    }
  }

  // ✅ NUEVO: Método para refrescar todos los datos
  Future<void> refrescarDatos() async {
    await Future.wait([
      _cargarEquipos(),
      _cargarJefesGuardia(),
      _cargarOperadorPorDni(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ NUEVO: Indicador de carga si las listas están vacías
            if (equipos.isEmpty || jefesGuardia.isEmpty)
              const LinearProgressIndicator(),
            _buildFormFields(),
            const SizedBox(height: 20),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = constraints.maxWidth;

        Map<String, double> fieldWeights = {
  'fecha': 0.8,
  'turno': 0.7,
  'equipo': 1.0,
  'codigo': 1.0,
  'modelo': 1.0,
  'operador': 1.2,
  'jefe': 1.2,
  'seccion': 1.0,
};

        double scaleFactor = cardWidth > 900
            ? 1.0
            : cardWidth > 700
            ? 0.9
            : cardWidth > 500
            ? 0.8
            : 0.7;

        return Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            _buildFlexibleField(
              width: _calculateFieldWidth(
                  cardWidth,
                  fieldWeights['fecha']! * scaleFactor),
              child: _buildFechaField(),
            ),

            _buildFlexibleField(
              width: _calculateFieldWidth(
                  cardWidth,
                  fieldWeights['turno']! * scaleFactor),
              child: CustomMaterialDropdown(
                label: 'Turno',
                value: widget.selectedTurno,
                items: turnos,
                onChanged:
                operacionBloqueada ? null : widget.onTurnoChanged,
                icon: Icons.access_time,
                hint: 'Turno',
                primaryColor: widget.primaryColor,
              ),
            ),

            _buildFlexibleField(
              width: _calculateFieldWidth(
                  cardWidth,
                  fieldWeights['equipo']! * scaleFactor),
              child: CustomMaterialDropdown(
                label: 'Equipo',
                value: selectedEquipo,
                items: equipos,
                onChanged: operacionBloqueada
                    ? null
                    : (value) {
                  setState(() {
    selectedEquipo = value;
    selectedCodigo = null;
    selectedModelo = null;

    codigosFiltrados = codigosPorEquipo[value] ?? [];
    modelosFiltrados = [];
  });
                },
                icon: Icons.precision_manufacturing,
                hint: equipos.isEmpty ? 'Cargando...' : 'Equipo',
                primaryColor: widget.primaryColor,
              ),
            ),

            _buildFlexibleField(
              width: _calculateFieldWidth(
                  cardWidth,
                  fieldWeights['codigo']! * scaleFactor),
              child: CustomMaterialDropdown(
  label: 'Código',
  value: selectedCodigo,
  items: codigosFiltrados,
  onChanged: operacionBloqueada || selectedEquipo == null
    ? null
    : (value) {
          setState(() {
            selectedCodigo = value;
            selectedModelo = null;

            modelosFiltrados = modelosPorCodigo[value] ?? [];
          });
        },
  icon: Icons.qr_code,
  hint: 'Código',
),
            ),

            _buildFlexibleField(
              width: _calculateFieldWidth(
                  cardWidth,
                  fieldWeights['modelo']! * scaleFactor),
              child: CustomMaterialDropdown(
                label: 'Modelo',
                value: selectedModelo,
                items: modelosFiltrados,
                onChanged: operacionBloqueada
                    ? null
                    : selectedCodigo != null
                    ? (value) =>
                    setState(() => selectedModelo = value)
                    : null,
                icon: Icons.model_training,
                hint: selectedCodigo == null
    ? 'Sel. código'
    : modelosFiltrados.isEmpty
        ? 'Sin modelos'
        : 'Modelo',
                primaryColor: widget.primaryColor,
              ),
            ),

            _buildFlexibleField(
              width: _calculateFieldWidth(
                  cardWidth,
                  fieldWeights['operador']! * scaleFactor),
              child: _buildOperadorField(),
            ),

            _buildFlexibleField(
              width: _calculateFieldWidth(
                  cardWidth,
                  fieldWeights['jefe']! * scaleFactor),
              child: CustomMaterialDropdown(
                label: 'Jefe Guardia',
                value: selectedJefeGuardia,
                items: jefesGuardia,
                onChanged: operacionBloqueada
                    ? null
                    : (value) =>
                    setState(() => selectedJefeGuardia = value),
                icon: Icons.person,
                hint: jefesGuardia.isEmpty ? 'Cargando...' : 'Jefe',
                primaryColor: widget.primaryColor,
              ),
            ),

            _buildFlexibleField(
              width: _calculateFieldWidth(
                  cardWidth,
                  fieldWeights['seccion']! * scaleFactor),
              child: CustomMaterialDropdown(
                label: 'Sección',
                value: selectedSeccion,
                items: secciones,
                onChanged: operacionBloqueada
                    ? null
                    : (value) =>
                    setState(() => selectedSeccion = value),
                icon: Icons.map,
                hint: 'Sección',
                primaryColor: widget.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFlexibleField(
      {required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }

  Widget _buildFechaField() {
    bool isEnabled = !operacionBloqueada;

    return InkWell(
      onTap: isEnabled ? _selectDate : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
              color: isEnabled
                  ? widget.primaryColor.withOpacity(0.5)
                  : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color:
          isEnabled ? Colors.white : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fecha',
                    style: TextStyle(
                      fontSize: 11,
                      color: isEnabled
                          ? widget.primaryColor
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    widget.fechaActual,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isEnabled
                          ? Colors.black87
                          : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: isEnabled
                  ? widget.primaryColor
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperadorField() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Operador',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600),
                ),
                Text(
                  operador ?? operadorEjemplo,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Icon(Icons.person_outline,
              size: 16,
              color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
        operacionBloqueada ? null : _crearOperacion,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding:
          const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 16),
            SizedBox(width: 6),
            Text(
              'CREAR OPERACIÓN',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateFieldWidth(double totalWidth, double weight) {
    double totalWeights =
        0.8 + 0.7 + 1.0 + 1.0 + 1.0 + 1.2 + 1.2 + 1.0;
    double spacing = 10 * 6;
    double padding = 16 * 2;
    double availableWidth =
        totalWidth - spacing - padding;
    return (availableWidth * weight) / totalWeights;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.fechaActual),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      String nuevaFecha =
      DateFormat('yyyy-MM-dd').format(picked);

      if (nuevaFecha != widget.fechaActual) {
        widget.onFechaChanged(nuevaFecha);
        _showSnackbar(
            'Fecha actualizada: $nuevaFecha',
            Colors.green);
      }
    }
  }

  void _crearOperacion() {
    if (widget.selectedTurno == null ||
        selectedEquipo == null ||
selectedCodigo == null ||
selectedModelo == null ||
        selectedJefeGuardia == null ||
        selectedSeccion == null) {
      _showSnackbar(
          'Complete todos los campos',
          Colors.orange);
      return;
    }

    widget.onOperacionCreada({
  'turno': widget.selectedTurno,
  'equipo': selectedEquipo,
  'codigo': selectedCodigo,
  'modelo': selectedModelo,
  'operador': operador ?? operadorEjemplo,
  'jefeGuardia': selectedJefeGuardia,
  'seccion': selectedSeccion,
  'fecha': widget.fechaActual,
});

    setState(() {
  selectedEquipo = null;
  selectedCodigo = null;
  selectedModelo = null;
  selectedJefeGuardia = null;
  selectedSeccion = null;
  codigosFiltrados = [];
  modelosFiltrados = [];
});

    _showSnackbar(
        'Operación creada exitosamente',
        Colors.green);
  }

  void _actualizarModelosPorCodigo(String? codigo) {
  if (codigo != null && modelosPorCodigo.containsKey(codigo)) {
    modelosFiltrados = modelosPorCodigo[codigo]!;
  } else {
    modelosFiltrados = [];
  }
}

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}