import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/screens/Envio%20a%20nube/Mediciones/horizontal/detalle_mediciones_screen.dart';
import 'package:i_miner/screens/widgets/envio%20nube/detalle_envio_screen.dart';
import 'package:i_miner/services/envio%20nube/AnfoChanger/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/Carguio/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/Dumper/ExportarDumperService.dart';
import 'package:i_miner/services/envio%20nube/Rompebancos/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/Scalamin/ExportarScalaminService.dart';
import 'package:i_miner/services/envio%20nube/SCISSOR/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/Sostenimiento/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/horizontal/exportar_service.dart';
import 'package:i_miner/services/envio%20nube/largo/exportar_service.dart';

class SeccionesScreen extends StatefulWidget {
  @override
  _SeccionesScreenState createState() => _SeccionesScreenState();
}

class _SeccionesScreenState extends State<SeccionesScreen> {
  final Color primaryColor = const Color(
    0xFF1B5E6B,
  ); // Color corporativo principal
  final Color accentColor = const Color(0xFF2C3E50); // Color de acento oscuro
  final Color backgroundColor = const Color(
    0xFFF5F7FA,
  ); // Fondo claro profesional

  late final DatabaseHelper _db;
  late final Map<String, Widget Function(BuildContext)> _pantallas;

  @override
  void initState() {
    super.initState();
    _db = DatabaseHelper();
    _pantallas = {
      "PERFORACIÓN TALADROS LARGOS": (context) => DetalleEnvioScreen(
        tipoOperacion: "PERFORACIÓN TALADROS LARGOS",
        endpointTipo: "tal_largo",
        fetchOperaciones: () => _db.getOperacionesTaladroLargo(),
        eliminarRegistro: (id) =>
            _db.eliminarOperacionTalLargoFisico(id).then((v) => v > 0),
        marcarComoEnviado: (id) => _db.actualizarEnvio(id),
        prepararDatosExportar: (ids, data) =>
            ExportarService(_db).prepararDatosParaExportar(ids, data),
        formatearJson: (data) => ExportarService(_db).formatearJson(data),
      ),

      "PERFORACIÓN HORIZONTAL": (context) => DetalleEnvioScreen(
        tipoOperacion: "PERFORACIÓN HORIZONTAL",
        endpointTipo: "tal_horizontal",
        fetchOperaciones: () => _db.getOperacionesTaladroHorizontal(),
        eliminarRegistro: (id) =>
            _db.eliminarOperacionTalHorizontalFisico(id).then((v) => v > 0),
        marcarComoEnviado: (id) => _db.actualizarEnvioHorizontal(id),
        prepararDatosExportar: (ids, data) =>
            ExportarHorizontalService(_db).prepararDatosParaExportar(ids, data),
        formatearJson: (data) =>
            ExportarHorizontalService(_db).formatearJson(data),
        isItemExportable: (item) =>
            item['identity_version'] == 2 && item['syncable'] == 1,
      ),

      "SOSTENIMIENTO": (context) => DetalleEnvioScreen(
        tipoOperacion: "SOSTENIMIENTO",
        endpointTipo: "empernador",
        fetchOperaciones: () => _db.getOperacionesTaladroEmpernador(),
        eliminarRegistro: (id) =>
            _db.eliminarOperacionTalEmpernadorFisico(id).then((v) => v > 0),
        marcarComoEnviado: (id) => _db.actualizarEnvioEmpernador(id),
        prepararDatosExportar: (ids, data) =>
            ExportarEmpernadorService(_db).prepararDatosParaExportar(ids, data),
        formatearJson: (data) =>
            ExportarEmpernadorService(_db).formatearJson(data),
      ),

      "ROMPEBANCO": (context) => DetalleEnvioScreen(
        tipoOperacion: "ROMPEBANCO",
        endpointTipo: "rompebanco",
        fetchOperaciones: () => _db.getOperacionesTaladroRompeBaco(),
        eliminarRegistro: (id) =>
            _db.eliminarOperacionTalRompeBacoFisico(id).then((v) => v > 0),
        marcarComoEnviado: (id) => _db.actualizarEnvioRompeBancos(id),
        prepararDatosExportar: (ids, data) =>
            ExportarRompebancoService(_db).prepararDatosParaExportar(ids, data),
        formatearJson: (data) =>
            ExportarRompebancoService(_db).formatearJson(data),
      ),

      "CARGUÍO": (context) => DetalleEnvioScreen(
        tipoOperacion: "CARGUÍO",
        endpointTipo: "carguio",
        fetchOperaciones: () => _db.getOperacionesTaladroCarguio(),
        eliminarRegistro: (id) =>
            _db.eliminarOperacionTalCarguioFisico(id).then((v) => v > 0),
        marcarComoEnviado: (id) => _db.actualizarEnvioCarguio(id),
        prepararDatosExportar: (ids, data) =>
            ExportarCarguioService(_db).prepararDatosParaExportar(ids, data),
        formatearJson: (data) =>
            ExportarCarguioService(_db).formatearJson(data),
      ),

      "DUMPER": (context) => DetalleEnvioScreen(
        tipoOperacion: "DUMPER",
        endpointTipo: "dumper",
        fetchOperaciones: () => _db.getOperacionesTaladroDumper(),
        eliminarRegistro: (id) =>
            _db.eliminarOperacionTalDumperFisico(id).then((v) => v > 0),
        marcarComoEnviado: (id) => _db.actualizarEnvioDumper(id),
        prepararDatosExportar: (ids, data) =>
            ExportarDumperService(_db).prepararDatosParaExportar(ids, data),
        formatearJson: (data) =>
            ExportarDumperService(_db).formatearJson(data),
      ),

      "ANFOCHANGER": (context) => DetalleEnvioScreen(
        tipoOperacion: "ANFOCHANGER",
        endpointTipo: "anfochanger",
        fetchOperaciones: () => _db.getOperacionesTaladroAnfoChanger(),
        eliminarRegistro: (id) =>
            _db.eliminarOperacionTalAnfochangerFisico(id).then((v) => v > 0),
        marcarComoEnviado: (id) => _db.actualizarEnvioRAnfoChanger(id),
        prepararDatosExportar: (ids, data) =>
            ExportarAnfoChangerService(_db)
                .prepararDatosParaExportar(ids, data),
        formatearJson: (data) =>
            ExportarAnfoChangerService(_db).formatearJson(data),
      ),

      "SCISSOR": (context) => DetalleEnvioScreen(
        tipoOperacion: "SCISSOR",
        endpointTipo: "scissor",
        fetchOperaciones: () => _db.getOperacionesTaladroscissor(),
        eliminarRegistro: (id) =>
            _db.eliminarOperacionTalScissorFisico(id).then((v) => v > 0),
        marcarComoEnviado: (id) => _db.actualizarEnvioscissor(id),
        prepararDatosExportar: (ids, data) =>
            ExportarScissorService(_db).prepararDatosParaExportar(ids, data),
        formatearJson: (data) =>
            ExportarScissorService(_db).formatearJson(data),
      ),

      "SCALAMIN": (context) => DetalleEnvioScreen(
        tipoOperacion: "SCALAMIN",
        endpointTipo: "scalamin",
        fetchOperaciones: () => _db.getOperacionesTaladroScalamin(),
        eliminarRegistro: (id) =>
            _db.eliminarOperacionTalScalaminFisico(id).then((v) => v > 0),
        marcarComoEnviado: (id) => _db.actualizarEnvioScalamin(id),
        prepararDatosExportar: (ids, data) =>
            ExportarScalaminService(_db).prepararDatosParaExportar(ids, data),
        formatearJson: (data) =>
            ExportarScalaminService(_db).formatearJson(data),
      ),

      "MEDICIONES TAL. HORIZONTAL": (context) =>
          ListaMedicionesScreen(tipoPerforacion: "HORIZONTAL"),
    };
  }

  final List<Map<String, dynamic>> _secciones = [
    {
      'nombre': "PERFORACIÓN TALADROS LARGOS",
      'icono': Icons.golf_course,
      'descripcion': "Taladros largos para producción",
    },
    {
      'nombre': "PERFORACIÓN HORIZONTAL",
      'icono': Icons.horizontal_rule,
      'descripcion': "Perforación horizontal y desarrollo",
    },
    {
      'nombre': "SOSTENIMIENTO",
      'icono': Icons.architecture,
      'descripcion': "Sostenimiento y fortificación",
    },
    {
      'nombre': "CARGUÍO",
      'icono': Icons.local_shipping,
      'descripcion': "Operaciones de carguío",
    },
    {
      'nombre': "DUMPER",
      'icono': Icons.local_shipping,
      'descripcion': "Operaciones de DUMPER",
    },
    {
      'nombre': "ROMPEBANCO",
      'icono': Icons.square_foot,
      'descripcion': "ROMPEBANCO generales",
    },
    {
      'nombre': "ANFOCHANGER",
      'icono': Icons.square_foot,
      'descripcion': "ROMPEBANCO generales",
    },
    {
      'nombre': "SCISSOR",
      'icono': Icons.square_foot,
      'descripcion': "ROMPEBANCO generales",
    },
    {
      'nombre': "SCALAMIN",
      'icono': Icons.square_foot,
      'descripcion': "SCALAMIN generales",
    },
    {
      'nombre': "MEDICIONES TAL. HORIZONTAL",
      'icono': Icons.straighten,
      'descripcion': "Mediciones perforación horizontal",
    },
    {
      'nombre': "MEDICIONES TAL. LARGO",
      'icono': Icons.height,
      'descripcion': "Mediciones perforación larga",
    },
  ];

  String searchQuery = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, backgroundColor],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildSeccionesList()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.dashboard_customize,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Panel de Control",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
          tooltip: 'Notificaciones',
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {},
          tooltip: 'Perfil',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bienvenido al Sistema",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Seleccione una sección para gestionar las operaciones mineras",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: "Buscar sección...",
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSeccionesList() {
    final filteredSecciones = _secciones.where((seccion) {
      if (searchQuery.isEmpty) return true;
      return seccion['nombre'].toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredSecciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No se encontraron secciones",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Aquí puedes agregar lógica de refresh si es necesario
        setState(() {});
      },
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: filteredSecciones.length,
        itemBuilder: (context, index) {
          final seccion = filteredSecciones[index];
          final String nombre = seccion['nombre'];
          final IconData icono = seccion['icono'];
          final String descripcion = seccion['descripcion'];
          final bool tienePantalla = _pantallas.containsKey(nombre);
          final bool disabled = seccion['disabled'] == true;

          return _buildSeccionCard(
            nombre: nombre,
            icono: icono,
            descripcion: descripcion,
            tienePantalla: tienePantalla,
            disabled: disabled,
          );
        },
      ),
    );
  }

  Widget _buildSeccionCard({
    required String nombre,
    required IconData icono,
    required String descripcion,
    required bool tienePantalla,
    bool disabled = false,
  }) {
    final bool isAvailable = tienePantalla && !disabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isAvailable
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: _pantallas[nombre]!),
                  );
                }
              : disabled
              ? null
              : () => _mostrarDialogo(context, nombre),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAvailable
                    ? primaryColor.withOpacity(0.2)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? primaryColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icono,
                    size: 28,
                    color: isAvailable ? primaryColor : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 16),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isAvailable
                                    ? const Color(0xFF1E293B)
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                          if (disabled) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Próximamente",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 13,
                          color: isAvailable
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicador de disponibilidad
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: Icon(
                    isAvailable ? Icons.arrow_forward_ios : Icons.lock_outline,
                    size: 16,
                    color: isAvailable ? primaryColor : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Total de secciones",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  "${_secciones.length} disponibles",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade200),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    "Último acceso",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getFormattedDate(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(now);
  }

  void _mostrarDialogo(BuildContext context, String seccion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                "Sección no disponible",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "La sección '$seccion' está en desarrollo.",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.build_circle,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pronto estará disponible para su uso",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text("Entendido"),
            ),
          ],
        );
      },
    );
  }
}
