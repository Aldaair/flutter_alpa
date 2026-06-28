import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/DimAla.dart';
import 'package:i_miner/models/DimArea.dart';
import 'package:i_miner/models/DimFase.dart';
import 'package:i_miner/models/DimLabor.dart';
import 'package:i_miner/models/DimMina.dart';
import 'package:i_miner/models/DimNivel.dart';
import 'package:i_miner/models/DimTipoLabor.dart';
import 'package:i_miner/models/DimZona.dart';
import 'package:i_miner/models/DimEstructuraMineral.dart';

class _LaborOption {
  final int laborId;
  final String laborNombre;
  final String tipoLabor;
  final String nivel;
  final String mina;
  final String zona;
  final String area;
  final String fase;
  final String estructuraMineral;

  const _LaborOption({
    required this.laborId,
    required this.laborNombre,
    required this.tipoLabor,
    required this.nivel,
    this.mina = '',
    this.zona = '',
    this.area = '',
    this.fase = '',
    this.estructuraMineral = '',
  });

  String get displayLabel => '$laborNombre | $nivel | $tipoLabor';

  String get searchText =>
      '$laborNombre $nivel $tipoLabor $mina $zona $area $fase $estructuraMineral';
}

class DialogoFormularioEmpernador extends StatefulWidget {
  final int operacionId;
  final int estadoId;
  final Map<String, dynamic>? datosIniciales;
  final String estado;
  final Color primaryColor;
  final Function(Map<String, dynamic>) onGuardar;

  const DialogoFormularioEmpernador({
    super.key,
    required this.operacionId,
    required this.estadoId,
    this.datosIniciales,
    required this.estado,
    this.primaryColor = const Color(0xFF1B5E6B),
    required this.onGuardar,
  });

  @override
  State<DialogoFormularioEmpernador> createState() =>
      _DialogoFormularioEmpernadorState();
}

class _DialogoFormularioEmpernadorState
    extends State<DialogoFormularioEmpernador> {
  bool isEditable = false;
  bool isLoading = false;

  final TextEditingController nPernosInstaladosController =
      TextEditingController();
  final TextEditingController mt52MallaController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();

  List<Map<String, dynamic>> pernosCompletos = [];
  List<String> tiposPerno = [];
  List<String> longitudesPerno = [];

  String? tipoPernoSeleccionado;
  String? longitudPernoSeleccionada;

  List<String> opcionesMalla = [];
  String? mallaSeleccionada;

  // Ubicación
  String? laborSeleccionada;
  int? laborIdSeleccionado;
  String? tipoLaborSeleccionado;
  String? nivelSeleccionado;
  String? alaSeleccionado;

  List<String> opcionesLabor = [];
  final Map<String, _LaborOption> _laborOptionMap = {};
  _LaborOption? _selectedOption;

  List<DimAla> alasCatalogo = [];

  String? sistematicoPuntualSeleccionado;

  List<String> opcionesSistematicoPuntual = ['Sistemático', 'Puntual'];

  @override
  void initState() {
    super.initState();
    isEditable = widget.estado.toLowerCase() != "cerrado";
    _cargarDatosIniciales();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    setState(() => isLoading = true);

    try {
      final dbHelper = DatabaseHelper();
      final results = await Future.wait([
        dbHelper.getPernos(),
        dbHelper.getMallas(),
        dbHelper.getPlanesMetrajeTL(),
        dbHelper.getPlanesAvanceTH(),
        dbHelper.getPlanesProduccion(),
        dbHelper.getMinas(),
        dbHelper.getDimZonas(),
        dbHelper.getAreas(),
        dbHelper.getFases(),
        dbHelper.getTiposLabor(),
        dbHelper.getEstructurasMinerales(),
        dbHelper.getNiveles(),
        dbHelper.getAlas(),
        dbHelper.getLabores(),
      ]);

      final pernos = results[0] as List<Map<String, dynamic>>;
      final mallas = results[1] as List<Map<String, dynamic>>;

      final planMetrajeTL = results[2] as List;
      final planAvanceTH = results[3] as List;
      final planProduccion = results[4] as List;

      final minasCatalogo = results[5] as List<DimMina>;
      final zonasCatalogo = results[6] as List<DimZona>;
      final areasCatalogo = results[7] as List<DimArea>;
      final fasesCatalogo = results[8] as List<DimFase>;
      final tiposLaborCatalogo = results[9] as List<DimTipoLabor>;
      final estructurasMineralesCatalogo =
          results[10] as List<DimEstructuraMineral>;
      final nivelesCatalogo = results[11] as List<DimNivel>;
      alasCatalogo = results[12] as List<DimAla>;
      final laboresCatalogo = results[13] as List<DimLabor>;

      final laborIdsUnicos = <int>{};
      for (final plan in [
        ...planMetrajeTL,
        ...planAvanceTH,
        ...planProduccion,
      ]) {
        final id = _extractLaborId(plan);
        if (id != null) laborIdsUnicos.add(id);
      }

      final opciones = <_LaborOption>[];
      for (final laborId in laborIdsUnicos) {
        final labor = laboresCatalogo.cast<DimLabor?>().firstWhere(
          (l) => l?.laborId == laborId,
          orElse: () => null,
        );
        if (labor == null) continue;

        final tipoLabor = tiposLaborCatalogo.cast<DimTipoLabor?>().firstWhere(
          (t) => t?.tipoLaborId == labor.tipoLaborId,
          orElse: () => null,
        );
        final nivel = nivelesCatalogo.cast<DimNivel?>().firstWhere(
          (n) => n?.nivelId == labor.nivelId,
          orElse: () => null,
        );
        final mina = minasCatalogo.cast<DimMina?>().firstWhere(
          (m) => m?.minaId == labor.minaId,
          orElse: () => null,
        );
        final zona = zonasCatalogo.cast<DimZona?>().firstWhere(
          (z) => z?.zonaId == labor.zonaId,
          orElse: () => null,
        );
        final area = areasCatalogo.cast<DimArea?>().firstWhere(
          (a) => a?.areaId == labor.areaId,
          orElse: () => null,
        );
        final fase = fasesCatalogo.cast<DimFase?>().firstWhere(
          (f) => f?.faseId == labor.faseId,
          orElse: () => null,
        );
        final estructura =
            estructurasMineralesCatalogo.cast<DimEstructuraMineral?>().firstWhere(
              (e) => e?.estructuraMineralId == labor.estructuraMineralId,
              orElse: () => null,
            );

        opciones.add(_LaborOption(
          laborId: labor.laborId,
          laborNombre: labor.nombreLabor,
          tipoLabor: tipoLabor?.nombre ?? '',
          nivel: nivel?.nombre ?? '',
          mina: mina?.nombre ?? '',
          zona: zona?.nombre ?? '',
          area: area?.nombre ?? '',
          fase: fase?.nombre ?? '',
          estructuraMineral: estructura?.nombre ?? '',
        ));
      }

      opciones.sort((a, b) => a.laborNombre.compareTo(b.laborNombre));

      if (!mounted) return;
      setState(() {
        pernosCompletos = pernos;
        tiposPerno = pernos
            .map((e) => e['tipo_perno']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        opcionesMalla = mallas
            .map((e) => e['tipo_malla']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        for (final opt in opciones) {
          opcionesLabor.add(opt.displayLabel);
          _laborOptionMap[opt.displayLabel] = opt;
        }
      });

      _preseleccionarLaborInicial(opciones);
    } catch (e) {
      print('Error cargando catálogos: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  int? _extractLaborId(dynamic plan) {
    if (plan is Map) return plan['laborId'] ?? plan['labor_id'];
    try {
      return (plan as dynamic).laborId as int?;
    } catch (_) {
      return null;
    }
  }

  void _preseleccionarLaborInicial(List<_LaborOption> opciones) {
    final laborInicial = widget.datosIniciales?['labor']?.toString() ?? '';
    if (laborInicial.isEmpty) return;
    if (opciones.isEmpty) return;

    final match = opciones.cast<_LaborOption?>().firstWhere(
      (o) => o!.laborNombre == laborInicial,
      orElse: () => null,
    );
    if (match != null) {
      _aplicarLaborOption(match);
    }
  }

  void _aplicarLaborOption(_LaborOption option) {
    setState(() {
      _selectedOption = option;
      laborSeleccionada = option.laborNombre;
      laborIdSeleccionado = option.laborId;
      tipoLaborSeleccionado = option.tipoLabor;
      nivelSeleccionado = option.nivel;
    });
  }

  void _onTipoPernoChanged(String? tipo) {
    setState(() {
      tipoPernoSeleccionado = tipo;
      longitudPernoSeleccionada = null;

      final filtrados =
          pernosCompletos
              .where((e) => e['tipo_perno'] == tipo)
              .map((e) => e['longitud'].toString())
              .toSet()
              .toList()
            ..sort((a, b) => double.parse(a).compareTo(double.parse(b)));

      longitudesPerno = filtrados;
    });
  }

  void _cargarDatosIniciales() {
    if (widget.datosIniciales == null) return;

    laborIdSeleccionado = widget.datosIniciales!['labor_id'] as int?;
    laborSeleccionada = widget.datosIniciales!['labor']?.toString();
    alaSeleccionado = widget.datosIniciales!['ala']?.toString();

    tipoPernoSeleccionado = widget.datosIniciales!['tipo_pernos'];
    longitudPernoSeleccionada = widget.datosIniciales!['log_pernos'];
    nPernosInstaladosController.text =
        widget.datosIniciales!['n_pernos_instalados'] ?? '';
    mallaSeleccionada = widget.datosIniciales!['tipo_malla'];
    mt52MallaController.text = widget.datosIniciales!['mt52_malla'] ?? '';
    sistematicoPuntualSeleccionado =
        widget.datosIniciales!['sistematico_puntual'];
    observacionesController.text =
        widget.datosIniciales!['observaciones'] ?? '';
  }

  Future<void> _guardarDatos() async {
    Map<String, dynamic> datosFormulario = {
      'labor_id': laborIdSeleccionado,
      'labor': laborSeleccionada ?? '',
      'tipo_labor': tipoLaborSeleccionado ?? '',
      'ala': alaSeleccionado ?? '',
      'nivel': nivelSeleccionado ?? '',
      'tipo_pernos': tipoPernoSeleccionado ?? '',
      'log_pernos': longitudPernoSeleccionada ?? '',
      'n_pernos_instalados': nPernosInstaladosController.text,
      'tipo_malla': mallaSeleccionada ?? '',
      'mt52_malla': mt52MallaController.text,
      'sistematico_puntual': sistematicoPuntualSeleccionado ?? '',
      'observaciones': observacionesController.text,
    };

    widget.onGuardar(datosFormulario);
    _mostrarSnackbar('Formulario guardado correctamente', Colors.green);
    Navigator.pop(context);
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    nPernosInstaladosController.dispose();
    mt52MallaController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1000,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSeccionLabor(),
                          const SizedBox(height: 16),
                          _buildSeccionPernos(),
                          const SizedBox(height: 16),
                          _buildSeccionMalla(),
                          const SizedBox(height: 16),
                          _buildSeccionObservaciones(),
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
      ),
    );
  }

  // -------------------- SECCIÓN LABOR --------------------

  Widget _buildSeccionLabor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.factory, size: 14, color: Colors.green),
              ),
              const SizedBox(width: 6),
              const Text(
                'Labor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RawAutocomplete<String>(
            initialValue: TextEditingValue(text: laborSeleccionada ?? ''),
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) return opcionesLabor;
              return opcionesLabor.where(
                (label) => label.toLowerCase().contains(query),
              );
            },
            onSelected: isEditable
                ? (value) {
                    final option = _laborOptionMap[value];
                    if (option != null) {
                      _aplicarLaborOption(option);
                    }
                  }
                : null,
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: isEditable,
                onChanged: (value) {
                  setState(() {
                    laborSeleccionada = value;
                    laborIdSeleccionado = null;
                    _selectedOption = null;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar labor...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 500,
                    height: 240,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final label = options.elementAt(index);
                        final option = _laborOptionMap[label];
                        return ListTile(
                          dense: true,
                          title: Text(
                            option?.laborNombre ?? label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: option != null
                              ? Text(
                                  '${option.nivel} | ${option.tipoLabor}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                              : null,
                          trailing: option != null
                              ? Text(
                                  option.mina,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                )
                              : null,
                          onTap: () => onSelected(label),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          if (opcionesLabor.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No hay labores disponibles en los planes de producción',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
          if (_selectedOption != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_selectedOption!.mina} / ${_selectedOption!.zona} / '
              '${_selectedOption!.area} / ${_selectedOption!.fase}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${_selectedOption!.estructuraMineral} / ${_selectedOption!.nivel} / '
              '${_selectedOption!.tipoLabor}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildDropdownField(
              label: 'Ala',
              value: alaSeleccionado,
              items: _uniqueSorted(alasCatalogo.map((a) => a.nombre)),
              onChanged: isEditable
                  ? (value) => setState(() => alaSeleccionado = value)
                  : null,
              icon: Icons.compare_arrows,
            ),
          ],
        ],
      ),
    );
  }

  // -------------------- SECCIÓN PERNOS --------------------

  Widget _buildSeccionPernos() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.build, size: 14, color: Colors.blue),
              ),
              const SizedBox(width: 6),
              const Text(
                'Pernos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Tipo Perno',
                  value: tipoPernoSeleccionado,
                  items: tiposPerno,
                  onChanged: isEditable ? _onTipoPernoChanged : null,
                  icon: Icons.category,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownField(
                  label: 'Longitud',
                  value: longitudPernoSeleccionada,
                  items: longitudesPerno,
                  onChanged: (tipoPernoSeleccionado != null && isEditable)
                      ? (value) =>
                          setState(() => longitudPernoSeleccionada = value)
                      : null,
                  icon: Icons.straighten,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  label: 'N° Pernos Instalados',
                  controller: nPernosInstaladosController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- SECCIÓN MALLA --------------------

  Widget _buildSeccionMalla() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.grid_on, size: 14, color: Colors.purple),
              ),
              const SizedBox(width: 6),
              const Text(
                'Malla y Sistemático',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Tipo Malla',
                  value: mallaSeleccionada,
                  items: opcionesMalla,
                  onChanged: isEditable
                      ? (value) => setState(() => mallaSeleccionada = value)
                      : null,
                  icon: Icons.grid_3x3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  label: 'M2 Malla',
                  controller: mt52MallaController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownField(
                  label: 'Sistemático/Puntual',
                  value: sistematicoPuntualSeleccionado,
                  items: opcionesSistematicoPuntual,
                  onChanged: isEditable
                      ? (value) =>
                          setState(() => sistematicoPuntualSeleccionado = value)
                      : null,
                  icon: Icons.timeline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- SECCIÓN OBSERVACIONES --------------------

  Widget _buildSeccionObservaciones() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, size: 16, color: widget.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Observaciones',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: observacionesController,
            enabled: isEditable,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Escriba observaciones adicionales...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.all(10),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- WIDGETS REUTILIZABLES --------------------

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        enabled: isEditable,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
    required IconData icon,
  }) {
    final valueExists = value != null && items.contains(value);

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valueExists ? value : null,
          hint: Row(
            children: [
              Icon(icon, size: 14, color: widget.primaryColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: widget.primaryColor),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: isEditable ? onChanged : null,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: widget.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.build, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Formulario de Empernador',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildEstadoBadge(),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isEditable
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditable ? Colors.green : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isEditable ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isEditable ? 'EDITABLE' : 'LECTURA',
            style: TextStyle(
              color: isEditable ? Colors.green : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 8),
          if (isEditable)
            ElevatedButton(
              onPressed: _guardarDatos,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save, size: 14),
                  SizedBox(width: 6),
                  Text('Guardar'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<String> _uniqueSorted(Iterable<String> values) {
    final unique = values
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    unique.sort();
    return unique;
  }
}
