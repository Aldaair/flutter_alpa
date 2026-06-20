class ApiConfig {
  static const String baseUrl = 'http://localhost:5000/api';
  //'https://api-seminco-catalina-huanca.vercel.app/api';
  //'https://backend-seminco-pro-02.vercel.app/api';
  //'https://backend-seminco-mina-02.onrender.com/api';
  // 'https://backendseminco-production.up.railway.app/api';
  static const String loginEndpoint = '/auth/login';
  static const String estadosEndpoint = '/estado/';
  static const String checklistEndpoint = '/check-list';
  static const String jefe_guardias = '/usuarios/jefes-guardia';
  static const String equipoEndpoint = '/equipo/';
  static const String tipoPerforacionEndpoint = '/tipo-perforaciones/';

  static const String PlanProduccionEndpoint = '/PlanProduccion/';
  static const String planMetrajeTLEndpoint = '/planes/metraje-tl/';
  static const String periodosEndpoint = '/planes/periodos';

  static const String PlanMensualEndpoint = '/PlanMensual/';
  static const String misLaboresEndpoint = '/mis-labores';
  static const String tipoHorometroEndpoint = '/tipo-horometro';
  static const String equipoHorometroTiposEndpoint = '/Equipo/horometro-tipos';
  static const String checklistTelemandoEndpoint = '/checklists-telemando';
  static const String ZonasEndpoint = '/planes/zonas';
  static const String longitudBarrasEndpoint = '/longitud-barras/';
  static const String pernosEndpoint = '/pernos/';
  static const String mallasEndpoint = '/mallas/';
  static const String OrigenDestinoEndpoint = '/origen-destino/';

  static const String AccesorioEndpoint = '/Accesorios/';
  static const String datosExploracionesEndpoint = '/NubeDatosExploraciones';
  static const String datosExploracionesmedionesEndpoint =
      '/NubeDatosExploraciones/Explo-medicion';
  static const String medicionesHorizontalEndpoint = '/medicion-tal-horizontal';

  // Catálogos de planeamiento
  static const String minasEndpoint = '/planes/minas';
  static const String areasEndpoint = '/planes/areas';
  static const String fasesEndpoint = '/planes/fases';
  static const String tipoLaboresEndpoint = '/planes/tipos-labor';
  static const String estructurasMineralesEndpoint =
      '/planes/estructuras-minerales';
  static const String nivelesEndpoint = '/planes/niveles';
  static const String alasEndpoint = '/planes/alas';
  static const String laboresEndpoint = '/planes/labores';
  static const String turnosEndpoint = '/planes/turnos';
  static const String procesosEndpoint = '/procesos';
}
