import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/config/data/shared_catalog_repository.dart';

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

class _OrigenDestinoOption {
  const _OrigenDestinoOption({required this.id, required this.nombre});

  final int? id;
  final String nombre;
}

class _DialogoFormularioPerforacionState
    extends State<DialogoFormularioPerforacion> {
  bool isEditable = false;
  bool isLoading = true;
  bool isSmallScreen = false;

  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController nCucharasController = TextEditingController();
  final TextEditingController nCarrosController = TextEditingController();
  String? equipoOperacionNombre;

  String? ubicacionInicioSeleccionada;
  int? ubicacionInicioId;

  String? ubicacionDestinoSeleccionado;
  int? ubicacionDestinoId;

  final SharedCatalogRepository _sharedCatalogRepository =
      SharedCatalogRepository();

  List<Map<String, dynamic>> todosLosOrigenes = [];
  List<Map<String, dynamic>> todosLosDestinos = [];
  List<Map<String, dynamic>> destinosDisponibles = [];
  List<_OrigenDestinoOption> origenesDisponibles = [];
  List<String> opcionesOrigen = [];
  List<String> opcionesDestino = [];

  bool get _usaCarritos {
    final equipo = equipoOperacionNombre?.trim().toUpperCase() ?? '';
    return equipo.contains('LOCOMOTORA');
  }

  String? get _filtroTipoEquipoDestino {
    if (_usaCarritos) {
      return 'LOCOMOTORA';
    }

    final equipo = equipoOperacionNombre?.trim().toUpperCase() ?? '';
    if (equipo.contains('VOLQUETE')) {
      return 'VOLQUETE';
    }

    return null;
  }

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
        _sharedCatalogRepository.getOrigenDestinoByProcesoAndTipo(
          proceso: 'ACARREO',
          tipo: 'ORIGEN',
        ),
        _sharedCatalogRepository.getOrigenDestinoByProcesoAndTipo(
          proceso: 'ACARREO',
          tipo: 'DESTINO',
        ),
        db.database.then(
          (database) => database.query(
            'Operacion_acarreo',
            columns: ['equipo'],
            where: 'id = ?',
            whereArgs: [widget.operacionId],
            limit: 1,
          ),
        ),
      ]);

      if (!mounted) return;

      setState(() {
        todosLosOrigenes = List<Map<String, dynamic>>.from(
          results[0] as List<Map<String, dynamic>>,
        );
        todosLosDestinos = List<Map<String, dynamic>>.from(
          results[1] as List<Map<String, dynamic>>,
        );
        final operacionRows = results[2] as List<Map<String, Object?>>;
        equipoOperacionNombre = operacionRows.isNotEmpty
            ? operacionRows.first['equipo']?.toString()
            : null;
        _aplicarFiltroOrigenes();
        _aplicarFiltroDestinos();
      });
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

    ubicacionInicioSeleccionada =
        widget.datosIniciales!['ubicacion_inicio']?.toString() ??
        widget.datosIniciales!['frente_origen']?.toString() ??
        widget.datosIniciales!['labor']?.toString();
    ubicacionInicioId =
        _asInt(widget.datosIniciales!['ubicacion_inicio_id']) ??
        _asInt(widget.datosIniciales!['labor_id']);
    ubicacionDestinoSeleccionado = widget.datosIniciales!['ubicacion_destino']
        ?.toString();
    ubicacionDestinoId = _asInt(widget.datosIniciales!['ubicacion_destino_id']);
    nCucharasController.text =
        widget.datosIniciales!['n_cucharas']?.toString() ??
        widget.datosIniciales!['n_viajes']?.toString() ??
        '';
    nCarrosController.text =
        widget.datosIniciales!['n_carros']?.toString() ?? '';
    observacionesController.text =
        widget.datosIniciales!['observaciones']?.toString() ?? '';
  }

  void _aplicarFiltroOrigenes() {
    origenesDisponibles = todosLosOrigenes
        .map(
          (origen) => _OrigenDestinoOption(
            id: _asInt(origen['id']),
            nombre: origen['nombre']?.toString() ?? '',
          ),
        )
        .where((origen) => origen.nombre.trim().isNotEmpty)
        .toList();
    print("ORIGENES DISPONIBLES");
    print(origenesDisponibles);

    opcionesOrigen = origenesDisponibles
        .map((origen) => origen.nombre)
        .toList();

    if (ubicacionInicioSeleccionada != null &&
        !opcionesOrigen.contains(ubicacionInicioSeleccionada)) {
      ubicacionInicioSeleccionada = null;
      ubicacionInicioId = null;
    }
  }

  _OrigenDestinoOption? _resolveSelectedOrigin() {
    final selectedName = ubicacionInicioSeleccionada?.trim();
    for (final origen in origenesDisponibles) {
      if (selectedName != null &&
          selectedName.isNotEmpty &&
          origen.nombre == selectedName) {
        return origen;
      }
      if (ubicacionInicioId != null && origen.id == ubicacionInicioId) {
        return origen;
      }
    }

    return null;
  }

  void _aplicarFiltroDestinos() {
    final tipoEquipo = _filtroTipoEquipoDestino;

    destinosDisponibles = tipoEquipo == null
        ? List<Map<String, dynamic>>.from(todosLosDestinos)
        : todosLosDestinos.where((destino) {
            final destinoTipoEquipo =
                destino['tipo_equipo']?.toString().trim().toUpperCase() ?? '';
            return destinoTipoEquipo == tipoEquipo;
          }).toList();

    opcionesDestino = destinosDisponibles
        .map((d) => d['nombre']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    if (ubicacionDestinoSeleccionado != null &&
        !opcionesDestino.contains(ubicacionDestinoSeleccionado)) {
      ubicacionDestinoSeleccionado = null;
      ubicacionDestinoId = null;
    }
  }

  Future<void> _guardarDatos() async {
    final origenSeleccionado = _resolveSelectedOrigin();
    if (origenSeleccionado == null) {
      _mostrarSnackbar(
        'Debe seleccionar una opción válida en Ubicación INICIO',
        Colors.orange,
      );
      return;
    }

    final datosFormulario = <String, dynamic>{
      'ubicacion_inicio_id': origenSeleccionado.id,
      'ubicacion_inicio': origenSeleccionado.nombre,
      'labor_id': origenSeleccionado.id,
      'labor': origenSeleccionado.nombre,
      'frente_origen': origenSeleccionado.nombre,
      'tipo_labor': '',
      'ala': '',
      'ala_id': null,
      'nivel': '',
      'ubicacion_destino_id': ubicacionDestinoId ?? 0,
      'ubicacion_destino': ubicacionDestinoSeleccionado ?? '',
      'observaciones': observacionesController.text,
      if (_usaCarritos) 'n_carros': int.tryParse(nCarrosController.text) ?? 0,
      if (!_usaCarritos)
        'n_cucharas': int.tryParse(nCucharasController.text) ?? 0,
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

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void dispose() {
    nCucharasController.dispose();
    nCarrosController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    isSmallScreen = screenWidth < 600;

    final dialogWidth = isSmallScreen ? screenWidth * 0.95 : 1000.0;
    final dialogHeight = isSmallScreen
        ? MediaQuery.of(context).size.height * 0.9
        : 750.0;

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
                          _buildSeccionAcarreo(),
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
    final options = List<String>.from(opcionesOrigen)..sort();

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
          _buildSearchableAutocompleteField(
            label: 'Seleccionar origen',
            hintText: 'Buscar origen compartido...',
            options: options,
            selectedValue: ubicacionInicioSeleccionada,
            onChanged: (value) {
              if (value == ubicacionInicioSeleccionada) return;
              setState(() {
                ubicacionInicioSeleccionada = value.trim().isEmpty
                    ? null
                    : value;
                ubicacionInicioId = null;
              });
            },
            onSelected: (value) {
              final option = origenesDisponibles.firstWhere(
                (item) => item.nombre == value,
                orElse: () => const _OrigenDestinoOption(id: null, nombre: ''),
              );
              if (option.nombre.isEmpty) return;
              setState(() {
                ubicacionInicioSeleccionada = option.nombre;
                ubicacionInicioId = option.id;
              });
            },
          ),
          if (opcionesOrigen.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No hay orígenes compartidos disponibles para Acarreo',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
          if (ubicacionInicioSeleccionada != null &&
              ubicacionInicioSeleccionada!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ubicacionInicioSeleccionada!,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                      ubicacionDestinoId = _asInt(destino['id']);
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

  Widget _buildSeccionAcarreo() {
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
                'Detalles de acarreo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (equipoOperacionNombre != null &&
              equipoOperacionNombre!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Equipo: $equipoOperacionNombre',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          _buildCompactTextField(
            controller: _usaCarritos ? nCarrosController : nCucharasController,
            label: _usaCarritos ? 'N° carritos' : 'N° cucharas',
            hintText: '0',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              isSmallScreen ? 'Acarreo' : 'Acarreo operation',
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

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      enabled: isEditable,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
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
