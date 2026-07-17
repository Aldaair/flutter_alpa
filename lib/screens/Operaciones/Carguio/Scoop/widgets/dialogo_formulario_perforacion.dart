import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/shared_catalog_repository.dart';
import 'package:i_miner/models/DimLabor.dart';

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

class _ScoopFrontOption {
  const _ScoopFrontOption({
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

  final int? laborId;
  final int? alaId;
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

  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController nCucharasController = TextEditingController();

  String? laborSeleccionada;
  int? laborIdSeleccionado;
  String? tipoLaborSeleccionado;
  String? alaSeleccionado;
  String? nivelSeleccionado;
  String? ubicacionDestinoSeleccionado;
  int? ubicacionDestinoId;

  int laborFieldResetKey = 0;
  int alaFieldResetKey = 0;

  List<DimLabor> laboresCatalogo = [];
  List<Map<String, dynamic>> destinosDisponibles = [];
  List<String> opcionesUbicacionDestino = [];

  _ScoopFrontOption? selectedManualFront;
  String? selectedManualFrontLabel;
  final Map<String, _ScoopFrontOption> _manualFrontMap = {};
  final SharedCatalogRepository _sharedCatalogRepository =
      SharedCatalogRepository();

  @override
  void initState() {
    super.initState();
    isEditable = widget.estado.toLowerCase() != 'cerrado';
    _cargarDatosIniciales();
    _cargarDatosDesdeBD();
  }

  Future<void> _cargarDatosDesdeBD() async {
    setState(() => isLoading = true);

    try {
      final dbHelper = DatabaseHelper();
      print('Cargando datos de scoop desde la base de datos...');
      print(widget.procesoId);

      final results = await Future.wait([
        _sharedCatalogRepository.getLabores(),
        dbHelper.getOrigenDestino('CARGUIO', 'DESTINO'),
      ]);

      if (!mounted) return;
      setState(() {
        laboresCatalogo = results[0] as List<DimLabor>;
        destinosDisponibles = results[1] as List<Map<String, dynamic>>;
        opcionesUbicacionDestino = destinosDisponibles
            .map((destino) => destino['nombre']?.toString() ?? '')
            .where((nombre) => nombre.isNotEmpty)
            .toList();
      });

      _rebuildManualFrontMap();
    } catch (e) {
      print('Error cargando datos de scoop: $e');
      if (!mounted) return;
      setState(() {
        laboresCatalogo = [];
        destinosDisponibles = [];
        opcionesUbicacionDestino = [];
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _cargarDatosIniciales() {
    if (widget.datosIniciales == null) return;

    laborIdSeleccionado = widget.datosIniciales!['labor_id'] as int?;
    laborSeleccionada = widget.datosIniciales!['labor']?.toString();
    tipoLaborSeleccionado = widget.datosIniciales!['tipo_labor']?.toString();
    alaSeleccionado = widget.datosIniciales!['ala']?.toString();
    nivelSeleccionado = widget.datosIniciales!['nivel']?.toString();
    ubicacionDestinoId =
        widget.datosIniciales!['destino_id'] as int? ??
        widget.datosIniciales!['ubicacion_destino_id'] as int?;
    ubicacionDestinoSeleccionado = widget.datosIniciales!['ubicacion_destino']
        ?.toString();

    nCucharasController.text =
        widget.datosIniciales!['n_cucharas']?.toString() ?? '0';
    observacionesController.text =
        widget.datosIniciales!['observaciones']?.toString() ?? '';
  }

  void _rebuildManualFrontMap() {
    _manualFrontMap.clear();

    void registerOption(_ScoopFrontOption option) {
      if (option.tipoLabor.trim().isEmpty || option.labor.trim().isEmpty) {
        return;
      }
      final label = _buildSelectionLabel(
        option.tipoLabor,
        option.labor,
        option.ala,
        option.nivel,
      );
      _manualFrontMap[label] = option;
    }

    for (final labor in laboresCatalogo) {
      registerOption(
        _ScoopFrontOption(
          laborId: labor.laborId,
          alaId: labor.alaId,
          tipoLabor: labor.tipoLaborNombre,
          labor: labor.nombreLabor,
          ala: labor.alaNombre,
          mina: labor.minaNombre,
          zona: labor.zonaNombre,
          area: labor.areaNombre,
          fase: labor.faseNombre,
          estructuraMineral: labor.estructuraMineralNombre,
          nivel: labor.nivelNombre,
        ),
      );
    }

    final label = selectedManualFrontLabel ?? _buildSelectionLabelFromState();
    if (label != null) {
      selectedManualFront = _manualFrontMap[label];
    }
  }

  String _buildSelectionLabel(
    String tipoLabor,
    String labor, [
    String? ala,
    String? nivel,
  ]) {
    final base = '${tipoLabor.trim()} - ${labor.trim()}';
    final normalizedAla = ala?.trim() ?? '';
    final normalizedNivel = nivel?.trim() ?? '';

    final parts = <String>[base];
    if (normalizedAla.isNotEmpty) {
      parts.add(normalizedAla);
    }
    if (normalizedNivel.isNotEmpty) {
      parts.add('Nivel $normalizedNivel');
    }

    return parts.join(' - ');
  }

  String? _buildSelectionLabelFromState() {
    final tipoLabor = tipoLaborSeleccionado?.trim();
    final labor = laborSeleccionada?.trim();
    if (tipoLabor == null || tipoLabor.isEmpty) return null;
    if (labor == null || labor.isEmpty) return null;
    return _buildSelectionLabel(
      tipoLabor,
      labor,
      alaSeleccionado,
      nivelSeleccionado,
    );
  }

  _ScoopFrontOption? _resolveManualFrontSelection() {
    final label = selectedManualFrontLabel ?? _buildSelectionLabelFromState();
    if (label == null) return null;
    return _manualFrontMap[label];
  }

  Map<String, dynamic> _buildLaborPayload() {
    final manualFront = _resolveManualFrontSelection();

    return <String, dynamic>{
      'labor_id': manualFront?.laborId,
      'labor': manualFront?.labor ?? '',
      'tipo_labor': manualFront?.tipoLabor ?? '',
      'ala': manualFront?.ala ?? '',
      'ala_id': manualFront?.alaId,
      'nivel': manualFront?.nivel ?? '',
    };
  }

  void _clearManualFrontSelection() {
    setState(() {
      selectedManualFront = null;
      selectedManualFrontLabel = null;
      laborIdSeleccionado = null;
      tipoLaborSeleccionado = null;
      laborSeleccionada = null;
      alaSeleccionado = null;
      nivelSeleccionado = null;
    });
  }

  void _aplicarManualFront(_ScoopFrontOption option) {
    setState(() {
      laborIdSeleccionado = option.laborId;
      tipoLaborSeleccionado = option.tipoLabor;
      laborSeleccionada = option.labor;
      alaSeleccionado = option.ala;
      nivelSeleccionado = option.nivel;
      selectedManualFront = option;
      selectedManualFrontLabel = _buildSelectionLabel(
        option.tipoLabor,
        option.labor,
        option.ala,
        option.nivel,
      );
    });
  }

  String _normalizeSearchValue(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> _guardarDatos() async {
    final destinoSeleccionado = destinosDisponibles.firstWhere(
      (destino) => destino['nombre'] == ubicacionDestinoSeleccionado,
      orElse: () => <String, dynamic>{},
    );
    final destinoId =
        (destinoSeleccionado['id'] as int?) ?? ubicacionDestinoId ?? 0;

    final datosFormulario = <String, dynamic>{
      ..._buildLaborPayload(),
      'frente_origen': 'otro_frente',
      'destino_id': destinoId,
      'ubicacion_destino_id': destinoId,
      'ubicacion_destino': ubicacionDestinoSeleccionado ?? '',
      'n_cucharas': int.tryParse(nCucharasController.text) ?? 0,
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
    observacionesController.dispose();
    nCucharasController.dispose();
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
                          _buildSeccionUbicacionDestino(),
                          const SizedBox(height: 16),
                          _buildSeccionCucharas(),
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

  Widget _buildSeccionLabor() {
    final selected = _resolveManualFrontSelection() ?? selectedManualFront;
    final selectedDetails = selected?.laborId != null ? selected : null;
    final options = _manualFrontMap.keys.toList()..sort();

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
            options: options,
            selectedValue:
                selectedManualFrontLabel ?? _buildSelectionLabelFromState(),
            onChanged: (value) {
              if (value !=
                  (selectedManualFrontLabel ??
                      _buildSelectionLabelFromState())) {
                _clearManualFrontSelection();
              }
            },
            onSelected: (value) {
              final option = _manualFrontMap[value];
              if (option != null) {
                _aplicarManualFront(option);
              }
            },
          ),
          if (selectedDetails != null) ...[
            const SizedBox(height: 8),
            Text(
              '${selectedDetails.estructuraMineral} / Nivel ${selectedDetails.nivel} / ${selectedDetails.tipoLabor} / ${selectedDetails.labor}${selectedDetails.ala.isNotEmpty ? ' / Ala ${selectedDetails.ala}' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionUbicacionDestino() {
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
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ubicación DESTINO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDropdownField(
            label: 'Seleccionar destino',
            value: ubicacionDestinoSeleccionado,
            items: opcionesUbicacionDestino,
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
          if (opcionesUbicacionDestino.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No hay destinos disponibles para Carguio',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeccionCucharas() {
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
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.calculate,
                  size: 14,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'N° Cucharas',
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
            controller: nCucharasController,
            enabled: isEditable,
            keyboardType: TextInputType.number,
            inputFormatters: const [],
            decoration: InputDecoration(
              hintText: 'Ingrese número entero',
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
              width: 420,
              height: 220,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: autocompleteOptions.length,
                itemBuilder: (context, index) {
                  final option = autocompleteOptions.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
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
            child: const Icon(Icons.description, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Formulario SCOOPTRAM',
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
