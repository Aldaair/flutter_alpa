import 'package:flutter/material.dart';
import 'package:i_miner/screens/widgets/envio%20nube/barra_seleccion.dart';
import 'package:i_miner/screens/widgets/envio%20nube/carga_dialog.dart';
import 'package:i_miner/screens/widgets/envio%20nube/confirmacion_dialog.dart';
import 'package:i_miner/screens/widgets/envio%20nube/empty_state.dart';
import 'package:i_miner/screens/widgets/envio%20nube/exito_dialog.dart';
import 'package:i_miner/screens/widgets/envio%20nube/loading_state.dart';
import 'package:i_miner/services/envio%20nube/operaciones_service.dart';

import 'operacion_card.dart';

class DetalleEnvioScreen extends StatefulWidget {
  final String tipoOperacion;
  final Color primaryColor;

  final Future<List<Map<String, dynamic>>> Function() fetchOperaciones;
  final Future<bool> Function(int id) eliminarRegistro;
  final Future<void> Function(int localId) marcarComoEnviado;

  final Future<List<Map<String, dynamic>>> Function(
    Set<int>,
    List<Map<String, dynamic>>,
  ) prepararDatosExportar;
  final String Function(List<Map<String, dynamic>>) formatearJson;

  final String endpointTipo;
  final bool Function(Map<String, dynamic>)? isItemExportable;

  const DetalleEnvioScreen({
    Key? key,
    required this.tipoOperacion,
    required this.endpointTipo,
    required this.fetchOperaciones,
    required this.eliminarRegistro,
    required this.marcarComoEnviado,
    required this.prepararDatosExportar,
    required this.formatearJson,
    this.primaryColor = const Color(0xFF1B5E6B),
    this.isItemExportable,
  }) : super(key: key);

  @override
  State<DetalleEnvioScreen> createState() => _DetalleEnvioScreenState();
}

class _DetalleEnvioScreenState extends State<DetalleEnvioScreen> {
  List<Map<String, dynamic>> operacionData = [];
  Set<int> selectedItems = {};
  bool isLoading = true;
  String mensajeUsuario = "Cargando registros...";

  @override
  void initState() {
    super.initState();
    _fetchOperacionData();
  }

  Future<void> _fetchOperacionData() async {
    try {
      final data = await widget.fetchOperaciones();

      setState(() {
        operacionData = data;
        isLoading = false;
        mensajeUsuario = data.isEmpty
            ? "No se encontraron registros para ${widget.tipoOperacion}"
            : "Datos cargados correctamente";
      });
    } catch (e) {
      setState(() {
        mensajeUsuario = "Error al cargar datos";
        isLoading = false;
        operacionData = [];
      });
    }
  }

  void _handleItemTap(int id) {
    final item = operacionData.firstWhere((e) => e['id'] == id);

    if (item['envio'] == 1) {
      _mostrarAdvertencia(
        'Registro ya enviado',
        'Este registro ya fue enviado y no se puede seleccionar nuevamente.',
      );
      return;
    }

    if (widget.isItemExportable != null &&
        !widget.isItemExportable!(item)) {
      _mostrarAdvertencia(
        'Registro no exportable',
        'Este registro no cumple los requisitos para ser exportado.',
      );
      return;
    }

    setState(() {
      if (selectedItems.contains(id)) {
        selectedItems.remove(id);
      } else {
        selectedItems.add(id);
      }
    });
  }

  void _confirmarEliminacion() {
    showDialog(
      context: context,
      builder: (context) => ConfirmacionDialog(
        titulo: 'Eliminar registros',
        mensaje:
            '¿Estás seguro de eliminar ${selectedItems.length} registro(s)?\nEsta acción no se puede deshacer.',
        textoConfirmar: 'Eliminar',
        confirmColor: Colors.red,
        onConfirmar: _eliminarRegistrosSeleccionados,
      ),
    );
  }

  Future<void> _eliminarRegistrosSeleccionados() async {
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const CargaDialog(mensaje: 'Eliminando registros...'),
    );

    try {
      int totalEliminados = 0;

      for (var id in selectedItems) {
        final result = await widget.eliminarRegistro(id);
        if (result) totalEliminados++;
      }

      if (!mounted) return;
      Navigator.pop(context);
      await _fetchOperacionData();

      setState(() => selectedItems.clear());

      showDialog(
        context: context,
        builder: (context) => ExitoDialog(
          titulo: 'Eliminación exitosa',
          mensaje:
              'Se eliminaron $totalEliminados registro(s) correctamente',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _mostrarError('Error al eliminar: ${e.toString()}');
    }
  }

  Future<void> _exportSelectedItems() async {
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const CargaDialog(mensaje: 'Preparando datos...'),
    );

    try {
      final jsonDataList = await widget.prepararDatosExportar(
        selectedItems,
        operacionData,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (jsonDataList.isEmpty) {
        _mostrarAdvertencia(
          'Sin datos exportables',
          'Los registros seleccionados no contienen datos válidos para exportar.',
        );
        return;
      }

      final jsonString = widget.formatearJson(jsonDataList);

      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) =>
            _buildJsonPreviewDialog(jsonString, jsonDataList.length),
      );

      if (confirmado == true) {
        await _enviarDatosALaNube(jsonDataList);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _mostrarError('Error al preparar datos: ${e.toString()}');
    }
  }

  Widget _buildJsonPreviewDialog(String jsonString, int cantidad) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.cloud_upload, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Confirmar envío',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Se enviarán $cantidad operaciones a la nube',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.grey.shade200),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: SelectableText(
                              jsonString,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                    top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Enviar a la nube'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarDatosALaNube(
      List<Map<String, dynamic>> jsonData) async {
    final operacionService = OperacionesService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const CargaDialog(mensaje: 'Enviando a la nube...'),
    );

    try {
      final dataParaEnviar = jsonData.map((item) {
        final copia = Map<String, dynamic>.from(item);
        copia.remove('local_id');
        return copia;
      }).toList();

      final success =
          await operacionService.crear(widget.endpointTipo, dataParaEnviar);

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        for (var item in jsonData) {
          final localId = item['local_id'] as int;
          await widget.marcarComoEnviado(localId);
        }

        await _fetchOperacionData();
        setState(() => selectedItems.clear());

        showDialog(
          context: context,
          builder: (context) => ExitoDialog(
            titulo: '¡Envío exitoso!',
            mensaje:
                'Se enviaron ${jsonData.length} operaciones correctamente',
          ),
        );
      } else {
        _mostrarError('Error al enviar datos al servidor');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _mostrarError('Error en envío: ${e.toString()}');
    }
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _mostrarAdvertencia(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          BarraSeleccion(
            cantidadSeleccionados: selectedItems.length,
            onEliminar: _confirmarEliminacion,
            onExportar: _exportSelectedItems,
            primaryColor: widget.primaryColor,
          ),
          Expanded(
            child: isLoading
                ? const LoadingState()
                : operacionData.isEmpty
                    ? EmptyState(
                        mensaje: mensajeUsuario,
                        subtitulo: 'No hay registros disponibles',
                        icono: Icons.inbox,
                      )
                    : _buildOperacionesList(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.list_alt, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.tipoOperacion,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: widget.primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () async {
            setState(() => isLoading = true);
            await _fetchOperacionData();
          },
          tooltip: 'Refrescar',
        ),
      ],
    );
  }

  Widget _buildOperacionesList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: operacionData.length,
      itemBuilder: (context, index) {
        final item = operacionData[index];
        final isSelected = selectedItems.contains(item['id']);
        final yaEnviado = item['envio'] == 1;

        return OperacionCard(
          operacion: item,
          isSelected: isSelected,
          isEnviado: yaEnviado,
          onTap: () => _handleItemTap(item['id']),
          primaryColor: widget.primaryColor,
        );
      },
    );
  }
}
