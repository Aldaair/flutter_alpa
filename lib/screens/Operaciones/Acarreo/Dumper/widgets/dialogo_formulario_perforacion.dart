import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/plan_avance_th.dart';
import 'package:i_miner/models/plan_metraje_tl.dart';
import 'package:i_miner/models/plan_produccion.dart';

class DialogoFormularioPerforacion extends StatefulWidget {
  final int operacionId;
  final int estadoId;
  final int procesoId;
  final Map<String, dynamic>? datosIniciales;
  final String estado;
  final Color primaryColor;
  final Function(Map<String, dynamic>) onGuardar;

  const DialogoFormularioPerforacion({
    super.key,
    required this.operacionId,
    required this.estadoId,
    required this.procesoId,
    this.datosIniciales,
    required this.estado,
    this.primaryColor = const Color(0xFF1B5E6B),
    required this.onGuardar,
  });

  @override
  State<DialogoFormularioPerforacion> createState() =>
      _DialogoFormularioPerforacionState();
}

class _DumperFrontOption {
  const _DumperFrontOption({
    required this.laborId,
    required this.alaId,
    required this.tipoLabor,
    required this.labor,
    required this.ala,
    required this.mina,
    required this.zona,
    required this.area,
    required this.fase,
    required this.estructuraMineral,
    required this.nivel,
  });

  final int laborId;
  final int alaId;
  final String tipoLabor;
  final String labor;
  final String ala;
  final String mina;
  final String zona;
  final String area;
  final String fase;
  final String estructuraMineral;
  final String nivel;
}

class _DialogoFormularioPerforacionState
    extends State<DialogoFormularioPerforacion> {
  bool isEditable = false;
  bool isLoading = true;
  bool isSmallScreen = false;

  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController nViajesController = TextEditingController();

  String? tipoLaborSeleccionado;
  String? laborInicioSeleccionado;
  String? alaSeleccionado;
  String? nivelSeleccionado;
  int? laborInicioId;

  String? ubicacionDestinoSeleccionado;
  int? ubicacionDestinoId;

  int laborFieldResetKey = 0;
  int alaFieldResetKey = 0;

  final Map<String, _DumperFrontOption> _frontOptionMap = {};
  _DumperFrontOption? selectedFrontOption;

  List<Map<String, dynamic>> destinosDisponibles = [];
  List<String> opcionesDestino = [];
  List<PlanMetrajeTL> planesMetrajeTLCompletos = [];
  List<PlanAvanceTH> planesAvanceTHCompletos = [];
  List<PlanProduccion> planesProduccionCompletos = [];

  @override
  void initState() {
    super.initState();
    isEditable = widget.estado.toLowerCase() != 'cerrado';
    _cargarDatosIniciales();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => isLoading = true);

    try {
      final db = DatabaseHelper();
      final results = await Future.wait([
        db.getPlanesMetrajeTL(),
        db.getPlanesAvanceTH(),
        db.getPlanesProduccion(),
        db.getDestinosByProcesoId(widget.procesoId),
      ]);

      if (!mounted) return;

      setState(() {
        planesMetrajeTLCompletos = results[0] as List<PlanMetrajeTL>;
        planesAvanceTHCompletos = results[1] as List<PlanAvanceTH>;
        planesProduccionCompletos = results[2] as List<PlanProduccion>;
        destinosDisponibles = results[3] as List<Map<String, dynamic>>;
        opcionesDestino = destinosDisponibles
            .map((d) => d['nombre']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      });

      _rebuildFrontOptions();
      _preseleccionarInicio();
    } catch (e) {
      print('Error cargando datos de Dumper: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _cargarDatosIniciales() {
    if (widget.datosIniciales == null) return;

    laborInicioSeleccionado = widget.datosIniciales!['labor']?.toString();
    laborInicioId = widget.datosIniciales!['labor_id'] as int?;
    tipoLaborSeleccionado = widget.datosIniciales!['tipo_labor']?.toString();
    alaSeleccionado = widget.datosIniciales!['ala']?.toString();
    nivelSeleccionado = widget.datosIniciales!['nivel']?.toString();
    ubicacionDestinoSeleccionado =
        widget.datosIniciales!['ubicacion_destino']?.toString();
    ubicacionDestinoId = widget.datosIniciales!['ubicacion_destino_id'] as int?;
    nViajesController.text = widget.datosIniciales!['n_viajes']?.toString() ?? '';
    observacionesController.text =
        widget.datosIniciales!['observaciones']?.toString() ?? '';
  }

  void _rebuildFrontOptions() {
    _frontOptionMap.clear();

    void registerOption(_DumperFrontOption option) {
      if (option.tipoLabor.trim().isEmpty ||
          option.labor.trim().isEmpty ||
          option.ala.trim().isEmpty) {
        return;
      }
      final label = _buildSelectionLabel(option.tipoLabor, option.labor, option.ala);
      _frontOptionMap[label] = option;
    }

    for (final plan in planesMetrajeTLCompletos) {
      registerOption(_DumperFrontOption(
        laborId: plan.laborId,
        alaId: plan.alaId,
        tipoLabor: plan.tipoLaborNombre,
        labor: plan.laborNombre,
        ala: plan.alaNombre,
        mina: plan.minaNombre,
        zona: plan.zonaNombre,
        area: plan.areaNombre,
        fase: plan.faseNombre,
        estructuraMineral: plan.estructuraMineralNombre,
        nivel: plan.nivelNombre,
      ));
    }

    for (final plan in planesAvanceTHCompletos) {
      registerOption(_DumperFrontOption(
        laborId: plan.laborId,
        alaId: plan.alaId,
        tipoLabor: plan.tipoLaborNombre,
        labor: plan.laborNombre,
        ala: plan.alaNombre,
        mina: plan.minaNombre,
        zona: plan.zonaNombre,
        area: plan.areaNombre,
        fase: plan.faseNombre,
        estructuraMineral: plan.estructuraMineralNombre,
        nivel: plan.nivelNombre,
      ));
    }

    for (final plan in planesProduccionCompletos) {
      registerOption(_DumperFrontOption(
        laborId: plan.laborId,
        alaId: plan.alaId,
        tipoLabor: plan.tipoLaborNombre,
        labor: plan.laborNombre,
        ala: plan.alaNombre,
        mina: plan.minaNombre,
        zona: plan.zonaNombre,
        area: plan.areaNombre,
        fase: plan.faseNombre,
        estructuraMineral: plan.estructuraMineralNombre,
        nivel: plan.nivelNombre,
      ));
    }
  }

  void _preseleccionarInicio() {
    final label = _buildSelectionLabelFromState();
    if (label == null) return;
    final option = _frontOptionMap[label];
    if (option != null) {
      _aplicarFrontOption(option);
    }
  }

  String _buildSelectionLabel(String tipoLabor, String labor, String ala) {
    return '${tipoLabor.trim()} - ${labor.trim()} - ${ala.trim()}';
  }

  String? _buildSelectionLabelFromState() {
    final tipoLabor = tipoLaborSeleccionado?.trim();
    final labor = laborInicioSeleccionado?.trim();
    final ala = alaSeleccionado?.trim();
    if (tipoLabor == null || tipoLabor.isEmpty) return null;
    if (labor == null || labor.isEmpty) return null;
    if (ala == null || ala.isEmpty) return null;
    return _buildSelectionLabel(tipoLabor, labor, ala);
  }

  _DumperFrontOption? _resolveSelectedFront() {
    final label = _buildSelectionLabelFromState();
    if (label == null) return null;
    return _frontOptionMap[label];
  }

  void _aplicarFrontOption(_DumperFrontOption option) {
    setState(() {
      tipoLaborSeleccionado = option.tipoLabor;
      laborInicioSeleccionado = option.labor;
      alaSeleccionado = option.ala;
      nivelSeleccionado = option.nivel;
      laborInicioId = option.laborId;
      selectedFrontOption = option;
    });
  }

  Future<void> _guardarDatos() async {
    final selected = _resolveSelectedFront();
    if (selected == null) {
      _mostrarSnackbar('Debe seleccionar una opción válida en Ubicación INICIO', Colors.orange);
      return;
    }

    final datosFormulario = <String, dynamic>{
      'labor_id': selected.laborId,
      'labor': selected.labor,
      'tipo_labor': selected.tipoLabor,
      'ala': selected.ala,
      'nivel': selected.nivel,
      'ubicacion_destino_id': ubicacionDestinoId ?? 0,
      'ubicacion_destino': ubicacionDestinoSeleccionado ?? '',
      'n_viajes': int.tryParse(nViajesController.text) ?? 0,
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
    nViajesController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    isSmallScreen = screenWidth < 600;

    final dialogWidth = isSmallScreen ? screenWidth * 0.95 : 1000.0;
    final dialogHeight =
        isSmallScreen ? MediaQuery.of(context).size.height * 0.9 : 750.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxWidth: 1000, maxHeight: dialogHeight),
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
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSeccionUbicacionInicio(),
                          const SizedBox(height: 16),
                          _buildSeccionUbicacionFin(),
                          const SizedBox(height: 16),
                          _buildSeccionViajes(),
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

  Widget _buildSeccionUbicacionInicio() {
    final selected = _resolveSelectedFront() ?? selectedFrontOption;
    final hasTipoLaborSeleccionado =
        tipoLaborSeleccionado != null && tipoLaborSeleccionado!.trim().isNotEmpty;
    final hasLaborSeleccionada =
        laborInicioSeleccionado != null && laborInicioSeleccionado!.trim().isNotEmpty;

    final tipos = _frontOptionMap.values
        .map((option) => option.tipoLabor)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final labores = _frontOptionMap.values
        .where(
          (option) =>
              tipoLaborSeleccionado == null ||
              tipoLaborSeleccionado!.isEmpty ||
              option.tipoLabor == tipoLaborSeleccionado,
        )
        .map((option) => option.labor)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final alas = _frontOptionMap.values
        .where(
          (option) =>
              (tipoLaborSeleccionado == null ||
                  tipoLaborSeleccionado!.isEmpty ||
                  option.tipoLabor == tipoLaborSeleccionado) &&
              (laborInicioSeleccionado == null ||
                  laborInicioSeleccionado!.isEmpty ||
                  option.labor == laborInicioSeleccionado),
        )
        .map((option) => option.ala)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
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
                child: const Icon(
                  Icons.play_circle_outline,
                  size: 14,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ubicación INICIO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildThreeAutocompleteRow(
            first: _buildSearchableAutocompleteField(
              label: 'Tipo Labor',
              hintText: 'Buscar tipo labor...',
              options: tipos,
              selectedValue: tipoLaborSeleccionado,
              onChanged: (value) {
                setState(() {
                  tipoLaborSeleccionado = value;
                  laborInicioSeleccionado = null;
                  alaSeleccionado = null;
                  laborInicioId = null;
                  selectedFrontOption = null;
                  laborFieldResetKey++;
                  alaFieldResetKey++;
                });
              },
              onSelected: (value) {
                setState(() {
                  tipoLaborSeleccionado = value;
                  laborInicioSeleccionado = null;
                  alaSeleccionado = null;
                  laborInicioId = null;
                  selectedFrontOption = null;
                  laborFieldResetKey++;
                  alaFieldResetKey++;
                });
              },
            ),
            second: _buildSearchableAutocompleteField(
              label: 'Labor',
              hintText: 'Buscar labor...',
              options: labores,
              selectedValue: laborInicioSeleccionado,
              enabled: hasTipoLaborSeleccionado,
              resetKey: laborFieldResetKey,
              onChanged: (value) {
                setState(() {
                  laborInicioSeleccionado = value;
                  alaSeleccionado = null;
                  laborInicioId = null;
                  selectedFrontOption = null;
                  alaFieldResetKey++;
                });
              },
              onSelected: (value) {
                setState(() {
                  laborInicioSeleccionado = value;
                  alaSeleccionado = null;
                  laborInicioId = null;
                  selectedFrontOption = null;
                  alaFieldResetKey++;
                });
              },
            ),
            third: _buildSearchableAutocompleteField(
              label: 'Ala',
              hintText: 'Buscar ala...',
              options: alas,
              selectedValue: alaSeleccionado,
              enabled: hasLaborSeleccionada,
              resetKey: alaFieldResetKey,
              onChanged: (value) {
                setState(() {
                  alaSeleccionado = value;
                  laborInicioId = null;
                  selectedFrontOption = null;
                });
              },
              onSelected: (value) {
                setState(() {
                  alaSeleccionado = value;
                });
                final option = _resolveSelectedFront();
                if (option != null) {
                  _aplicarFrontOption(option);
                }
              },
            ),
          ),
          if (_frontOptionMap.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No hay labores disponibles en los planes',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
          if (selected != null) ...[
            const SizedBox(height: 8),
            Text(
              '${selected.mina} / ${selected.zona} / ${selected.area} / ${selected.fase}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${selected.estructuraMineral} / ${selected.nivel} / ${selected.tipoLabor} / ${selected.labor}${selected.ala.isNotEmpty ? ' / Ala ${selected.ala}' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionUbicacionFin() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.stop_circle_outlined,
                  size: 14,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ubicación FIN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCompactDropdownField(
            label: 'Seleccionar destino',
            value: ubicacionDestinoSeleccionado,
            items: opcionesDestino,
            onChanged: isEditable
                ? (value) {
                    setState(() {
                      ubicacionDestinoSeleccionado = value;
                      final destino = destinosDisponibles.firstWhere(
                        (item) => item['nombre'] == value,
                        orElse: () => <String, dynamic>{},
                      );
                      ubicacionDestinoId = destino['id'] as int?;
                    });
                  }
                : null,
            icon: Icons.flag,
          ),
          if (opcionesDestino.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No hay destinos disponibles para Acarreo',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeccionViajes() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.timeline,
                  size: 14,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Número de Viajes (Cucharas)',
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
            controller: nViajesController,
            enabled: isEditable,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Ingrese número de viajes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

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
            maxLines: isSmallScreen ? 4 : 3,
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
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return options;
        return options.where((option) => option.toLowerCase().contains(query));
      },
      onSelected: isFieldEnabled ? onSelected : null,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: isFieldEnabled,
          onChanged: isFieldEnabled ? onChanged : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
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

  Widget _buildThreeAutocompleteRow({
    required Widget first,
    required Widget second,
    required Widget third,
  }) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second),
        const SizedBox(width: 8),
        Expanded(child: third),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 12,
      ),
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
            child: Icon(
              Icons.description,
              color: Colors.white,
              size: isSmallScreen ? 16 : 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSmallScreen ? 'Perforación' : 'Formulario de Perforación',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
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
              fontSize: isSmallScreen ? 8 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
    required IconData icon,
    Color color = Colors.blue,
  }) {
    final valueExists = value != null && items.contains(value);
    final isEnabled = onChanged != null && isEditable;

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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isSmallScreen ? 12 : 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  items.isEmpty ? 'Cargando...' : label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: isEnabled
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            size: isSmallScreen ? 16 : 18,
            color: color,
          ),
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 12,
            color: Colors.black87,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(6),
          items: items.isEmpty
              ? [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'No hay opciones',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ]
              : items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
          onChanged: isEnabled ? onChanged : null,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 10,
      ),
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: isSmallScreen ? 12 : 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isEditable)
            ElevatedButton(
              onPressed: _guardarDatos,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save, size: isSmallScreen ? 12 : 14),
                  const SizedBox(width: 6),
                  Text(
                    'Guardar',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
