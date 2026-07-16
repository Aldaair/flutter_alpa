import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_miner/config/data/shared_catalog_repository.dart';
import 'package:i_miner/models/DimLabor.dart';
import 'package:i_miner/models/malla.dart';
import 'package:i_miner/models/perno.dart';

class _LaborOption {
  final int? laborId;
  final int? alaId;
  final String laborNombre;
  final String tipoLabor;
  final String nivel;
  final String ala;
  final String mina;
  final String zona;
  final String area;
  final String fase;
  final String estructuraMineral;

  const _LaborOption({
    required this.laborId,
    required this.alaId,
    required this.laborNombre,
    required this.tipoLabor,
    required this.nivel,
    this.ala = '',
    this.mina = '',
    this.zona = '',
    this.area = '',
    this.fase = '',
    this.estructuraMineral = '',
  });

  String get displayLabel {
    final base = '$tipoLabor - $laborNombre';
    final parts = <String>[base];
    if (ala.trim().isNotEmpty) {
      parts.add(ala.trim());
    }
    if (nivel.trim().isNotEmpty) {
      parts.add('Nivel ${nivel.trim()}');
    }
    return parts.join(' - ');
  }

  String get searchText =>
      '$laborNombre $nivel $tipoLabor $ala $mina $zona $area $fase $estructuraMineral';
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

  final SharedCatalogRepository _sharedCatalogRepository =
      SharedCatalogRepository();

  List<Perno> pernosCompletos = [];
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
  String? _selectedLaborLabel;

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
      final results = await Future.wait([
        _sharedCatalogRepository.getPernos(),
        _sharedCatalogRepository.getMallas(),
        _sharedCatalogRepository.getLabores(),
      ]);

      final pernos = results[0] as List<Perno>;
      final mallas = results[1] as List<Malla>;
      final labores = results[2] as List<DimLabor>;

      final opciones = <_LaborOption>[];
      for (final labor in labores) {
        opciones.add(
          _LaborOption(
            laborId: labor.laborId,
            alaId: labor.alaId,
            laborNombre: labor.nombreLabor,
            tipoLabor: labor.tipoLaborNombre,
            nivel: labor.nivelNombre,
            ala: labor.alaNombre,
            mina: labor.minaNombre,
            zona: labor.zonaNombre,
            area: labor.areaNombre,
            fase: labor.faseNombre,
            estructuraMineral: labor.estructuraMineralNombre,
          ),
        );
      }

      opciones.sort((a, b) => a.laborNombre.compareTo(b.laborNombre));

      if (!mounted) return;
      setState(() {
        opcionesLabor = [];
        _laborOptionMap.clear();
        pernosCompletos = pernos;
        tiposPerno =
            pernos
                .map((e) => e.tipoPerno.trim())
                .where((n) => n.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        opcionesMalla =
            mallas
                .map((e) => e.tipoMalla.trim())
                .where((n) => n.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        for (final opt in opciones) {
          final label = opt.displayLabel;
          opcionesLabor.add(label);
          _laborOptionMap[label] = opt;
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

  void _preseleccionarLaborInicial(List<_LaborOption> opciones) {
    final laborInicial = widget.datosIniciales?['labor']?.toString() ?? '';
    final tipoLaborInicial =
        widget.datosIniciales?['tipo_labor']?.toString() ?? '';
    final alaInicial = widget.datosIniciales?['ala']?.toString() ?? '';
    final nivelInicial = widget.datosIniciales?['nivel']?.toString() ?? '';
    if (laborInicial.isEmpty) return;
    if (opciones.isEmpty) return;

    final match = opciones.cast<_LaborOption?>().firstWhere(
      (o) =>
          o!.laborNombre == laborInicial &&
          (tipoLaborInicial.isEmpty || o.tipoLabor == tipoLaborInicial) &&
          (alaInicial.isEmpty || o.ala == alaInicial) &&
          (nivelInicial.isEmpty || o.nivel == nivelInicial),
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
      alaSeleccionado = option.ala;
      _selectedLaborLabel = option.displayLabel;
    });
  }

  void _clearLaborSelection() {
    setState(() {
      _selectedOption = null;
      _selectedLaborLabel = null;
      laborSeleccionada = null;
      laborIdSeleccionado = null;
      tipoLaborSeleccionado = null;
      nivelSeleccionado = null;
      alaSeleccionado = null;
    });
  }

  Map<String, dynamic> _buildLaborPayload() {
    final selectedOption =
        _laborOptionMap[_selectedLaborLabel ?? _buildSelectionLabel() ?? ''];

    return <String, dynamic>{
      'labor_id': selectedOption?.laborId,
      'labor': selectedOption?.laborNombre ?? '',
      'tipo_labor': selectedOption?.tipoLabor ?? '',
      'ala': selectedOption?.ala ?? '',
      'ala_id': selectedOption?.alaId,
      'nivel': selectedOption?.nivel ?? '',
    };
  }

  void _onTipoPernoChanged(String? tipo) {
    setState(() {
      tipoPernoSeleccionado = tipo;
      longitudPernoSeleccionada = null;

      final filtrados =
          pernosCompletos
              .where((e) => e.tipoPerno == tipo)
              .map((e) => e.longitud.toString())
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
    tipoLaborSeleccionado = widget.datosIniciales!['tipo_labor']?.toString();
    nivelSeleccionado = widget.datosIniciales!['nivel']?.toString();
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
      ..._buildLaborPayload(),
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
    final selected = _selectedOption;
    final selectedDetails = selected?.laborId != null ? selected : null;
    final selectedLabel = _selectedLaborLabel ?? _buildSelectionLabel();

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
          _buildSearchableAutocompleteField(
            label: 'Frente de Trabajo',
            hintText: 'Buscar por tipo labor, labor o ala...',
            options: opcionesLabor,
            selectedValue: selectedLabel,
            onChanged: (value) {
              if (value != (_selectedLaborLabel ?? _buildSelectionLabel())) {
                _clearLaborSelection();
              }
            },
            onSelected: (value) {
              final option = _laborOptionMap[value];
              if (option != null) {
                _aplicarLaborOption(option);
              }
            },
          ),
          if (opcionesLabor.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No hay labores disponibles en el catálogo',
                style: TextStyle(fontSize: 12, color: Colors.red.shade400),
              ),
            ),
          if (selectedDetails != null) ...[
            const SizedBox(height: 8),
            Text(
              '${selectedDetails.mina} / ${selectedDetails.zona} / '
              '${selectedDetails.area} / ${selectedDetails.fase}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${selectedDetails.estructuraMineral} / ${selectedDetails.nivel} / '
              '${selectedDetails.tipoLabor}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  String? _buildSelectionLabel() {
    final tipoLabor = tipoLaborSeleccionado?.trim();
    final labor = laborSeleccionada?.trim();
    if (tipoLabor == null || tipoLabor.isEmpty) return null;
    if (labor == null || labor.isEmpty) return null;
    final parts = <String>['$tipoLabor - $labor'];
    final ala = alaSeleccionado?.trim() ?? '';
    final nivel = nivelSeleccionado?.trim() ?? '';
    if (ala.isNotEmpty) {
      parts.add(ala);
    }
    if (nivel.isNotEmpty) {
      parts.add('Nivel $nivel');
    }
    return parts.join(' - ');
  }

  String _normalizeSearchValue(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Widget _buildSearchableAutocompleteField({
    required String label,
    required String hintText,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSelected,
    bool enabled = true,
    int resetKey = 0,
  }) {
    final isFieldEnabled = isEditable && enabled;

    return RawAutocomplete<String>(
      key: ValueKey('$label-$resetKey'),
      initialValue: TextEditingValue(text: selectedValue ?? ''),
      optionsBuilder: (textEditingValue) {
        if (!isFieldEnabled) {
          return const Iterable<String>.empty();
        }
        final query = _normalizeSearchValue(textEditingValue.text);
        if (query.isEmpty) return options;
        return options.where(
          (option) => _normalizeSearchValue(option).contains(query),
        );
      },
      onSelected: isFieldEnabled ? onSelected : null,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: isFieldEnabled,
          onChanged: isFieldEnabled ? onChanged : null,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.search, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            isDense: true,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, autocompleteOptions) {
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
                itemCount: autocompleteOptions.length,
                itemBuilder: (context, index) {
                  final option = autocompleteOptions.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
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
                  icon: Icons.format_list_numbered,
                  keyboardType: TextInputType.number,
                  onlyDigits: true,
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
                child: const Icon(
                  Icons.grid_on,
                  size: 14,
                  color: Colors.purple,
                ),
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
                  icon: Icons.grid_on,
                  keyboardType: TextInputType.number,
                  onlyDigits: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownField(
                  label: 'Sistemático/Puntual',
                  value: sistematicoPuntualSeleccionado,
                  items: opcionesSistematicoPuntual,
                  onChanged: isEditable
                      ? (value) => setState(
                          () => sistematicoPuntualSeleccionado = value,
                        )
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
            style: const TextStyle(fontSize: 12),
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
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool onlyDigits = false,
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
        inputFormatters: onlyDigits
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          prefixIcon: Icon(icon, size: 14, color: widget.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
}
