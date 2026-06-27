import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';
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

class _DialogoFormularioPerforacionState
    extends State<DialogoFormularioPerforacion> {
  bool isEditable = false;
  bool isLoading = true;

  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController nCucharasController = TextEditingController();
  String? laborSeleccionada;
  int? laborIdSeleccionado;
  String? ubicacionDestinoSeleccionado;
  int? ubicacionDestinoId;

  List<PlanProduccion> planesProduccionCompletos = [];
  List<String> opcionesLabor = [];
  List<Map<String, dynamic>> destinosDisponibles = [];
  List<String> opcionesUbicacionDestino = [];

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
      final results = await Future.wait([
        dbHelper.getPlanesProduccion(),
        dbHelper.getDestinosByProcesoId(widget.procesoId),
      ]);

      final planes = results[0] as List<PlanProduccion>;
      final destinos = results[1] as List<Map<String, dynamic>>;
      final labores = <String>{};

      for (final plan in planes) {
        if (plan.laborNombre.trim().isNotEmpty) {
          labores.add(plan.laborNombre.trim());
        }
      }

      if (!mounted) return;
      setState(() {
        planesProduccionCompletos = planes;
        opcionesLabor = labores.toList()..sort();
        destinosDisponibles = destinos;
        opcionesUbicacionDestino = destinos
            .map((destino) => destino['nombre']?.toString() ?? '')
            .where((nombre) => nombre.isNotEmpty)
            .toList();
      });
    } catch (e) {
      print('Error cargando planes de produccion: $e');
      if (!mounted) return;
      setState(() {
        planesProduccionCompletos = [];
        opcionesLabor = [];
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
    ubicacionDestinoId = widget.datosIniciales!['ubicacion_destino_id'] as int?;
    ubicacionDestinoSeleccionado = widget.datosIniciales!['ubicacion_destino']
        ?.toString();

    nCucharasController.text =
        widget.datosIniciales!['n_cucharas']?.toString() ?? '0';
    observacionesController.text =
        widget.datosIniciales!['observaciones']?.toString() ?? '';
  }

  Future<void> _guardarDatos() async {
    final planProduccion = planesProduccionCompletos.firstWhere(
      (plan) => plan.laborNombre == laborSeleccionada,
      orElse: () => PlanProduccion(
        planProduccionId: 0,
        laborId: laborIdSeleccionado ?? 0,
        periodoId: 0,
        turnoId: 0,
        leyId: 0,
        procesoId: 0,
        procesoNombre: '',
        dia: 0,
        valor: 0,
        laborNombre: laborSeleccionada ?? '',
        turnoNombre: '',
        leyNombre: '',
        createdAt: null,
        updatedAt: null,
      ),
    );

    final destinoSeleccionado = destinosDisponibles.firstWhere(
      (destino) => destino['nombre'] == ubicacionDestinoSeleccionado,
      orElse: () => <String, dynamic>{},
    );
    final destinoId =
        (destinoSeleccionado['id'] as int?) ?? ubicacionDestinoId ?? 0;

    final Map<String, dynamic> datosFormulario = {
      'labor_id': planProduccion.laborId == 0 ? null : planProduccion.laborId,
      'labor': laborSeleccionada ?? '',
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
                (labor) => labor.toLowerCase().contains(query),
              );
            },
            onSelected: isEditable
                ? (value) {
                    setState(() {
                      laborSeleccionada = value;
                      final plan = planesProduccionCompletos.firstWhere(
                        (item) => item.laborNombre == value,
                        orElse: () => PlanProduccion(
                          planProduccionId: 0,
                          laborId: 0,
                          periodoId: 0,
                          turnoId: 0,
                          leyId: 0,
                          procesoId: 0,
                          procesoNombre: '',
                          dia: 0,
                          valor: 0,
                          laborNombre: value,
                          turnoNombre: '',
                          leyNombre: '',
                          createdAt: null,
                          updatedAt: null,
                        ),
                      );
                      laborIdSeleccionado = plan.laborId == 0
                          ? null
                          : plan.laborId;
                    });
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
                    width: 420,
                    height: 220,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
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
          ),
          if (opcionesLabor.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No hay labores disponibles en planes de producción',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
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
