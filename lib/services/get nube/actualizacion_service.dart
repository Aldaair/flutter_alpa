// ignore_for_file: use_rethrow_when_possible, avoid_print

import 'package:flutter/material.dart';
import 'package:i_miner/screens/Dash/actualizacion_dialog.dart';
import 'package:i_miner/services/get%20nube/Plan%20mensual/api_service_plan_mensual_avance.dart';
import 'package:i_miner/services/get%20nube/Plan%20mensual/api_service_plan_mensual_metraje.dart';
import 'package:i_miner/services/get%20nube/Plan%20mensual/api_service_plan_mensual_produccion.dart';
import 'package:i_miner/services/get%20nube/llamadas/ApiServiceAccesorio.dart';
import 'package:i_miner/services/get%20nube/llamadas/ApiServiceJefeGuardia.dart';
import 'package:i_miner/services/get%20nube/llamadas/ApiServiceTipoEquipo.dart';
import 'package:i_miner/services/get%20nube/llamadas/ApiServiceEquipoHorometroTipos.dart';
import 'package:i_miner/services/get%20nube/llamadas/ApiServiceTipoPerforacion.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_checklist.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_estado.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_longitud_barras.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_mallas.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_pernos.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_services_Equipo.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/services/user_service.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_zona.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_periodos.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_minas.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_dim_zonas.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_areas.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_fases.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_tipo_labores.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_estructuras_minerales.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_niveles.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_alas.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_labores.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_dim_turnos.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_destinos.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_cargos.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_usuario_directorio.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_procesos.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_categoria_estado.dart';

class ActualizacionService {
  final BuildContext context;
  final String token;
  final String dni;

  ActualizacionService({
    required this.context,
    required this.token,
    required this.dni,
  });

  // Mapeo de funciones de actualización
  late final Map<String, Future<void> Function()> _requests;

  void _inicializarRequests() {
    _requests = {
      "Estados": fetchEstados,
      "Checklist": fetchCheckList,
      "Tipos Perforación": fetchTiposPerforacion,
      "Equipos": fetchEquipo,
      "Longitud Barras": fetchLongitudBarras,
      "Pernos": fetchPernos,
      "Mallas": fetchMallas,
      "Horometros": fetchHorometros,
      "Plan TL": () => fetchPlanMetrajeTL(),
      "Plan TH": () => fetchPlanAvanceTH(),
      "Plan CARGUIO y ACARREO": () => fetchPlanProduccion(),
      "Jefes Guardia": fetchJefesGuardia,
      "Minas": fetchMinas,
      "Zonas": fetchDimZonas,
      "Areas": fetchAreas,
      "Fases": fetchFases,
      "Tipos Labor": fetchTiposLabor,
      "Estructuras Minerales": fetchEstructurasMinerales,
      "Niveles": fetchNiveles,
      "Alas": fetchAlas,
      "Labores": fetchLabores,
      "Turnos": fetchDimTurnos,
      "Procesos": fetchProcesos,
      "Destinos": fetchDestinos,
      //"Autorizaciones": refreshOfflineAuthorizationSnapshot,
      "Cargos": fetchCargos,
      "Usuarios": fetchUsuarios,
      "Categorías Estados": fetchCategoriasEstados,
      'Periodos': fetchPeriodos,
    };
  }

  // Método principal para ejecutar la actualización
  Future<void> ejecutarActualizacion(
    Map<String, bool> opcionesSeleccionadas,
  ) async {
    _inicializarRequests();

    // Mostrar diálogo de progreso inicial
    _mostrarDialogoProgreso('Iniciando actualización...');

    try {
      int total = opcionesSeleccionadas.values.where((v) => v).length;
      int completadas = 0;
      bool huboError = false;
      List<String> errores = [];

      // Ejecutar cada opción seleccionada
      for (var entry in _requests.entries) {
        if (opcionesSeleccionadas[entry.key] == true) {
          // Actualizar mensaje de progreso
          _actualizarDialogoProgreso(
            'Actualizando ${entry.key}...',
            subtitulo: '$completadas de $total completadas',
          );

          try {
            await entry.value();
            completadas++;
          } catch (e) {
            huboError = true;
            completadas++;
            errores.add('${entry.key}: $e');
            print("❌ Error en ${entry.key}: $e");
          }
        }
      }

      // Cerrar diálogo de progreso
      Navigator.of(context, rootNavigator: true).pop();

      // Mostrar resultado final
      _mostrarResultadoFinal(completadas, total, huboError, errores);
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _mostrarError('Error general: $e');
    }
  }

  void _mostrarDialogoProgreso(String mensaje, {String? subtitulo}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(message: mensaje, subtitulo: subtitulo),
    );
  }

  void _actualizarDialogoProgreso(String mensaje, {String? subtitulo}) {
    // Cerrar el diálogo actual y mostrar uno nuevo
    Navigator.of(context, rootNavigator: true).pop();
    _mostrarDialogoProgreso(mensaje, subtitulo: subtitulo);
  }

  void _mostrarResultadoFinal(
    int completadas,
    int total,
    bool huboError,
    List<String> errores,
  ) {
    String mensaje;
    Color color;

    if (completadas == total && !huboError) {
      mensaje =
          '✅ $completadas de $total actualizaciones completadas correctamente';
      color = Colors.green;
    } else if (completadas > 0) {
      mensaje =
          '⚠️ $completadas de $total completadas (${errores.length} fallaron)';
      color = Colors.orange;
    } else {
      mensaje = '❌ No se pudo completar ninguna actualización';
      color = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: errores.isNotEmpty
            ? SnackBarAction(
                label: 'VER ERRORES',
                textColor: Colors.white,
                onPressed: () => _mostrarDetalleErrores(errores),
              )
            : null,
      ),
    );
  }

  void _mostrarDetalleErrores(List<String> errores) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Errores de actualización'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: errores.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errores[index])),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> fetchEstados() async {
    final apiService = ApiServiceEstado();

    try {
      final estados = await apiService.fetchEstados(token);

      print("✅ Estados guardados en SQLite:");
    } catch (e) {
      print("❌ Error al actualizar estados: $e");
      throw e;
    }
  }

  Future<void> fetchCategoriasEstados() async {
    final apiService = ApiServiceCategoriaEstado();
    try {
      final categorias = await apiService.fetchCategoriasEstados(token);
      print("✅ Categorías de estados guardadas: ${categorias.length}");
    } catch (e) {
      print("❌ Error al actualizar categorías de estados: $e");
      throw e;
    }
  }

  Future<void> fetchTiposPerforacion() async {
    final apiService = ApiServiceTipoPerforacion();

    try {
      final tipos = await apiService.fetchTiposPerforacion(token);

      print("✅ Tipos de perforación guardados en SQLite:");

      for (var tipo in tipos) {
        print("Tipo: ${tipo.nombre}");
      }
    } catch (e) {
      print("❌ Error al actualizar tipos de perforación: $e");
      throw e;
    }
  }

  Future<void> fetchEquipo() async {
    final apiService = ApiServiceEquipo();

    try {
      final equipos = await apiService.fetchEquipos(token);

      print("✅ Equipos guardados en SQLite:");

      for (var equipo in equipos) {
        print("Equipo: ${equipo.nombre}");
      }
    } catch (e) {
      print("❌ Error al actualizar equipos: $e");
      throw e;
    }
  }

  Future<void> fetchLongitudBarras() async {
    final apiService = ApiServiceLongitudBarras();

    try {
      final lista = await apiService.fetchLongitudBarras(token);

      print("✅ Longitud Barras guardadas en SQLite:");

      for (var item in lista) {
        print("Proceso: ${item.proceso} | Longitud: ${item.longitudPies}");
      }
    } catch (e) {
      print("❌ Error al actualizar Longitud Barras: $e");
      throw e;
    }
  }

  Future<void> fetchPernos() async {
    final apiService = ApiServicePernos();

    try {
      final lista = await apiService.fetchPernos(token);

      print("✅ Pernos guardados en SQLite:");

      for (var item in lista) {
        print("Tipo: ${item.tipoPerno} | Longitud: ${item.longitud}");
      }
    } catch (e) {
      print("❌ Error al actualizar Pernos: $e");
      throw e;
    }
  }

  Future<void> fetchMallas() async {
    final apiService = ApiServiceMallas();

    try {
      final lista = await apiService.fetchMallas(token);

      print("✅ Mallas guardadas en SQLite:");

      for (var item in lista) {
        print("Tipo: ${item.tipoMalla}");
      }
    } catch (e) {
      print("❌ Error al actualizar Mallas: $e");
      throw e;
    }
  }

  Future<void> fetchHorometros() async {
    //final apiServiceHorometros = ApiServiceHorometros();
    final apiServiceTipos = ApiServiceTipoHorometro();
    final apiServiceEqTipos = ApiServiceEquipoHorometroTipos();

    try {
      //await apiServiceHorometros.fetchHorometros(token);
      //print("✅ Horómetros guardados en SQLite correctamente");

      await apiServiceTipos.fetchTiposHorometro(token);
      print("✅ Tipos de horómetro guardados en SQLite correctamente");

      await apiServiceEqTipos.fetchEquipoHorometroTipos(token);
      print("✅ Equipo-Horómetro tipos guardados en SQLite correctamente");
    } catch (e) {
      print("❌ Error al actualizar horómetros: $e");
      throw e;
    }
  }

  Future<void> fetchAccesorios() async {
    final apiService = ApiServiceAccesorio();

    try {
      await apiService.fetchAccesorios(token);

      print("✅ Accesorios guardados en SQLite correctamente");
    } catch (e) {
      print("❌ Error al actualizar accesorios: $e");
      throw e;
    }
  }

  Future<void> fetchCheckList() async {
    final apiService = ApiServiceCheckList();

    try {
      final items = await apiService.fetchCheckList(token);

      print("✅ Checklist guardado en SQLite:");

      for (var item in items) {
        print(
          "Item: ${item.nombre}",
        ); // reemplaza `nombre` con el campo que quieras mostrar
      }
    } catch (e) {
      print("❌ Error al actualizar checklist: $e");
      throw e;
    }
  }

  Future<void> fetchPdfsDelMes() async {}

  Future<void> fetchJefesGuardia() async {
    final apiService = ApiServiceJefeGuardia();

    try {
      final jefes = await apiService.fetchJefesGuardia(token);

      print("✅ Jefes de guardia guardados en SQLite:");

      for (var jefe in jefes) {
        print("Jefe: ${jefe.nombres} ${jefe.apellidos}");
      }
    } catch (e) {
      print("❌ Error al actualizar jefes de guardia: $e");
      throw e;
    }
  }

  Future<void> fetchProcesosAcero() async {}

  Future<void> fetchOperadores() async {
    // Tu implementación
  }

  Future<void> fetchZonas() async {
    final apiService = ApiServiceZona();

    try {
      final zonas = await apiService.fetchZonas(token);

      print("✅ Zonas guardadas en SQLite:");

      for (var zona in zonas) {
        print(
          "Zona: ${zona.nombre} | Mina: ${zona.minaId} | Codigo: ${zona.codigo}",
        );
      }
    } catch (e) {
      print("❌ Error al actualizar zonas: $e");
      throw e;
    }
  }

  Future<void> fetchPeriodos() async {
    final apiService = ApiServicePeriodos();

    try {
      final periodos = await apiService.fetchPeriodos(token);

      print("✅ Periodos guardados en SQLite:");

      for (final periodo in periodos) {
        print(
          "Periodo: ${periodo.periodoId} | ${periodo.tipo} ${periodo.numero}/${periodo.anno}",
        );
      }
    } catch (e) {
      print("❌ Error al actualizar periodos: $e");
      throw e;
    }
  }

  Future<void> fetchPlanMetrajeTL() async {
    final apiService = ApiServicePlanMetraje();

    try {
      await fetchPeriodos();
      final periodoVigente = await DatabaseHelper().getPeriodoVigente(
        tipo: 'SEMANAL',
      );
      final periodoId = periodoVigente?.periodoId;

      print(
        '🗓️ Periodo vigente TL: periodoId=${periodoVigente?.periodoId}, tipo=${periodoVigente?.tipo}, numero=${periodoVigente?.numero}, anno=${periodoVigente?.anno}, inicio=${periodoVigente?.fechaInicio}, fin=${periodoVigente?.fechaFin}',
      );

      if (periodoId == null) {
        throw Exception(
          'No se pudo resolver el periodo vigente desde dim_periodo para Plan Metraje.',
        );
      }

      final planes = await apiService.fetchPlanesMetraje(token, periodoId);

      print("✅ Plan Metraje TL guardado en SQLite:");

      for (final plan in planes) {
        print(
          "Labor: ${plan.laborNombre} | Veta: ${plan.anchoVetaMetros} | Sem: ${plan.anchoMinadoSemMetros} | Mes: ${plan.anchoMinadoMesMetros}",
        );
      }
    } catch (e) {
      print("❌ Error al actualizar Plan Metraje: $e");
      throw e;
    }
  }

  Future<void> fetchPlanAvanceTH() async {
    final apiService = ApiServicePlanAvance();

    try {
      await fetchPeriodos();
      final periodoVigente = await DatabaseHelper().getPeriodoVigente(
        tipo: 'MENSUAL',
      );
      final periodoId = periodoVigente?.periodoId;

      if (periodoId == null) {
        throw Exception(
          'No se pudo resolver el periodo vigente desde dim_periodo para Plan Avance.',
        );
      }

      final planes = await apiService.fetchPlanesAvance(token, periodoId);

      print("✅ Plan Avance TH guardado en SQLite:");
    } catch (e) {
      print("❌ Error al actualizar Plan Avance: $e");
      throw e;
    }
  }

  Future<void> fetchPlanProduccion() async {
    final apiService = ApiServicePlanProduccion();

    try {
      await fetchPeriodos();
      final periodoVigente = await DatabaseHelper().getPeriodoVigente(
        tipo: 'SEMANAL',
      );
      final periodoId = periodoVigente?.periodoId;

      if (periodoId == null) {
        throw Exception(
          'No se pudo resolver el periodo vigente desde dim_periodo para Plan Producción.',
        );
      }

      final planes = await apiService.fetchPlanesProduccion(token, periodoId);

      print("✅ Plan Producción guardado en SQLite:");
    } catch (e) {
      print("❌ Error al actualizar Plan Producción: $e");
      throw e;
    }
  }

  Future<void> refreshOfflineAuthorizationSnapshot() async {
    try {
      await UserService().syncOfflineProfileSnapshot(
        dni: dni,
        token: token,
        databaseHelper: DatabaseHelper(),
      );
      print('✅ Offline authorization snapshot refreshed');
    } catch (e) {
      print('❌ Error refreshing offline authorization snapshot: $e');
      rethrow;
    }
  }

  Future<void> fetchMinas() async {
    final apiService = ApiServiceMinas();

    try {
      final minas = await apiService.fetchMinas(token);

      print("✅ Minas guardadas en SQLite:");

      for (final mina in minas) {
        print("Mina: ${mina.nombre} | Codigo: ${mina.codigo}");
      }
    } catch (e) {
      print("❌ Error al actualizar minas: $e");
      throw e;
    }
  }

  Future<void> fetchDimZonas() async {
    final apiService = ApiServiceDimZonas();

    try {
      final zonas = await apiService.fetchDimZonas(token);

      print("✅ Catálogo zonas guardado en SQLite:");

      for (final zona in zonas) {
        print("Zona: ${zona.nombre} | MinaId: ${zona.minaId}");
      }
    } catch (e) {
      print("❌ Error al actualizar catálogo zonas: $e");
      throw e;
    }
  }

  Future<void> fetchAreas() async {
    final apiService = ApiServiceAreas();

    try {
      final areas = await apiService.fetchAreas(token);

      print("✅ Areas guardadas en SQLite:");

      for (final area in areas) {
        print("Area: ${area.nombre} | ZonaId: ${area.zonaId}");
      }
    } catch (e) {
      print("❌ Error al actualizar areas: $e");
      throw e;
    }
  }

  Future<void> fetchFases() async {
    final apiService = ApiServiceFases();

    try {
      final fases = await apiService.fetchFases(token);

      print("✅ Fases guardadas en SQLite:");

      for (final fase in fases) {
        print("Fase: ${fase.nombre} | Codigo: ${fase.codigo}");
      }
    } catch (e) {
      print("❌ Error al actualizar fases: $e");
      throw e;
    }
  }

  Future<void> fetchTiposLabor() async {
    final apiService = ApiServiceTipoLabores();

    try {
      final tipos = await apiService.fetchTiposLabor(token);

      print("✅ Tipos de labor guardados en SQLite:");

      for (final tipo in tipos) {
        print("Tipo labor: ${tipo.nombre} | Codigo: ${tipo.codigo}");
      }
    } catch (e) {
      print("❌ Error al actualizar tipos de labor: $e");
      throw e;
    }
  }

  Future<void> fetchEstructurasMinerales() async {
    final apiService = ApiServiceEstructurasMinerales();

    try {
      final estructuras = await apiService.fetchEstructurasMinerales(token);

      print("✅ Estructuras minerales guardadas en SQLite:");

      for (final estructura in estructuras) {
        print(
          "Estructura: ${estructura.nombre} | Codigo: ${estructura.codigo}",
        );
      }
    } catch (e) {
      print("❌ Error al actualizar estructuras minerales: $e");
      throw e;
    }
  }

  Future<void> fetchNiveles() async {
    final apiService = ApiServiceNiveles();

    try {
      final niveles = await apiService.fetchNiveles(token);

      print("✅ Niveles guardados en SQLite:");

      for (final nivel in niveles) {
        print("Nivel: ${nivel.nombre} | Numero: ${nivel.numero}");
      }
    } catch (e) {
      print("❌ Error al actualizar niveles: $e");
      throw e;
    }
  }

  Future<void> fetchAlas() async {
    final apiService = ApiServiceAlas();

    try {
      final alas = await apiService.fetchAlas(token);

      print("✅ Alas guardadas en SQLite:");

      for (final ala in alas) {
        print(
          "Ala: ${ala.nombre} | Codigo: ${ala.codigo} | Orden: ${ala.orden}",
        );
      }
    } catch (e) {
      print("❌ Error al actualizar alas: $e");
      throw e;
    }
  }

  Future<void> fetchLabores() async {
    final apiService = ApiServiceLabores();

    try {
      final labores = await apiService.fetchLabores(token);

      print("✅ Labores guardadas en SQLite:");

      for (final labor in labores) {
        print("Labor: ${labor.nombreLabor} | MinaId: ${labor.minaId}");
      }
    } catch (e) {
      print("❌ Error al actualizar labores: $e");
      throw e;
    }
  }

  Future<void> fetchDimTurnos() async {
    final apiService = ApiServiceDimTurnos();

    try {
      final turnos = await apiService.fetchDimTurnos(token);

      print("✅ Turnos guardados en SQLite:");

      for (final turno in turnos) {
        print("Turno: ${turno.nombre} | Codigo: ${turno.codigo}");
      }
    } catch (e) {
      print("❌ Error al actualizar turnos: $e");
      throw e;
    }
  }

  Future<void> fetchProcesos() async {
    final apiService = ApiServiceProcesos();

    try {
      final procesos = await apiService.fetchProcesos(token);

      print("✅ Procesos guardados en SQLite:");

      for (final proceso in procesos) {
        print("Proceso: ${proceso.nombre} | ID: ${proceso.id}");
      }
    } catch (e) {
      print("❌ Error al actualizar procesos: $e");
      throw e;
    }
  }

  Future<void> fetchDestinos() async {
    final apiService = ApiServiceDestinos();

    try {
      final destinos = await apiService.fetchDestinos(token);
      print("✅ Destinos guardados en SQLite: ${destinos.length}");
    } catch (e) {
      print("❌ Error al actualizar destinos: $e");
      throw e;
    }
  }

  Future<void> fetchCargos() async {
    final apiService = ApiServiceCargos();

    try {
      final cargos = await apiService.fetchCargos(token);

      print("✅ Cargos guardados en SQLite:");

      for (final cargo in cargos) {
        print("Cargo: ${cargo.nombre} | ID: ${cargo.cargoId}");
      }
    } catch (e) {
      print("❌ Error al actualizar cargos: $e");
      throw e;
    }
  }

  Future<void> fetchUsuarios() async {
    final apiService = ApiServiceUsuarioDirectorio();

    try {
      await apiService.fetchAll(token);
      print("✅ Usuarios guardados en shared DB");
    } catch (e) {
      print("❌ Error al actualizar usuarios: $e");
      throw e;
    }
  }
}
