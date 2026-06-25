import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_miner/config/data/database_helper.dart';

import 'package:i_miner/models/TipoPerforacion.dart';
import 'package:i_miner/screens/Operaciones/Mediciones/horizontal/listar_mediciones.dart';

class RegistroExplosivoPagelargo extends StatefulWidget {
  const RegistroExplosivoPagelargo({super.key});

  @override
  _RegistroExplosivoPagelargoState createState() =>
      _RegistroExplosivoPagelargoState();
}

class _RegistroExplosivoPagelargoState
    extends State<RegistroExplosivoPagelargo> {
  List<Map<String, dynamic>> exploraciones = [];
  List<Map<String, dynamic>> exploracionesFiltradas = [];
  List<Map<String, dynamic>> _exploraciones = [];
  List<TipoPerforacion> _tiposPerforacion = [];
  List<Map<String, dynamic>> _exploracionesSucio = [];
  bool _isLoading = true;
  Map<String, TextEditingController> controllers = {};

  Map<int, Map<String, dynamic>> registrosEditados = {};

  final TextEditingController fechaController = TextEditingController();
  final TextEditingController turnoController = TextEditingController();
  // Función para calcular el número de semana ISO
  int _calcularSemanaISO(DateTime date) {
    final dayOfYear = _diaDelAnio(date);
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();

    if (woy < 1) {
      return _calcularSemanaISO(DateTime(date.year - 1, 12, 31));
    } else if (woy > 52 && DateTime(date.year, 12, 31).weekday < 4) {
      return 1;
    }
    return woy;
  }

  int _diaDelAnio(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  final List<String> meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _getTiposPerforacion();
    _cargarExploraciones();
  }

  Future<void> _getTiposPerforacion() async {
    try {
      final dbHelper = DatabaseHelper();
      _tiposPerforacion = await dbHelper.getTiposPerforacionLargofil();
      print(
        "Tipos de Perforación obtenidos de la BD local: $_tiposPerforacion",
      );

      // Después de obtener los tipos, aplicar el filtro si ya tenemos las exploraciones
      if (_exploracionesSucio.isNotEmpty) {
        _filtrarExploraciones();
      }
    } catch (e) {
      print("Error al obtener los tipos de perforación: $e");
    }
  }

  Future<void> _cargarExploraciones() async {
    try {
      final dbHelper = DatabaseHelper();
      final exploraciones = await dbHelper.getExploraciones();

      setState(() {
        _exploracionesSucio = exploraciones;
        _isLoading = false;
      });

      // Si ya tenemos los tipos de perforación, aplicar el filtro
      if (_tiposPerforacion.isNotEmpty) {
        _filtrarExploraciones();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar exploraciones: $e')),
      );
    }
  }

  void _filtrarExploraciones() {
    // Extraemos los nombres de los tipos de perforación para comparar
    final nombresTipos = _tiposPerforacion
        .map((t) => t.nombre.toLowerCase())
        .toSet();

    setState(() {
      _exploraciones = _exploracionesSucio.where((exploracion) {
        final tipoExploracion = exploracion['tipo_perforacion']
            ?.toString()
            .toLowerCase();
        return tipoExploracion != null &&
            nombresTipos.contains(tipoExploracion);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mediciones'),
        backgroundColor: Color(0xFF21899C),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListaPantalla()),
              );
              // Esta línea se ejecutará cuando regreses de ListaPantalla
              _recargarDatos();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtros
            Row(
              children: [
                // Selector de fecha
                Flexible(
                  flex: 3,
                  child: TextField(
                    controller: fechaController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          fechaController.text =
                              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                // Dropdown para turno
                Flexible(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: turnoController.text.isEmpty
                        ? null
                        : turnoController.text,
                    decoration: InputDecoration(
                      labelText: 'Turno',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['Día', 'Noche'].map((String turno) {
                      return DropdownMenuItem<String>(
                        value: turno,
                        child: Text(turno),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        turnoController.text = newValue ?? '';
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                // Botón Buscar
                ElevatedButton.icon(
                  icon: Icon(Icons.search, size: 20),
                  label: Text('Buscar'),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Tablas dinámicas por tipo de perforación
            Expanded(
              child: ListView(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 3,
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(
                        'PERFORACIÓN TALADRO LARGO',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: false,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              // Tabla con todos los campos solicitados
                              SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Table(
                                  border: TableBorder.all(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey,
                                  ),
                                  columnWidths: const {
                                    0: FlexColumnWidth(0.8),
                                    1: FlexColumnWidth(1.2),
                                    2: FlexColumnWidth(1.2),
                                    3: FlexColumnWidth(1.2),
                                    4: FlexColumnWidth(1.4),
                                    5: FlexColumnWidth(1.2),
                                    6: FlexColumnWidth(1.3),
                                    7: FlexColumnWidth(1.4),
                                    8: FlexColumnWidth(1.3),
                                  },
                                  children: [
                                    // Encabezados de tabla
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(8),
                                        ),
                                      ),
                                      children: [
                                        tableCellBold(context, 'N°'),
                                        tableCellBold(context, 'FECHA'),
                                        tableCellBold(context, 'TURNO'),
                                        tableCellBold(context, 'EMPRESA'),
                                        tableCellBold(context, 'ZONA'),
                                        tableCellBold(context, 'LABOR'),
                                        tableCellBold(context, 'VETA'),
                                        tableCellBold(
                                          context,
                                          'TIPO PERFORACIÓN',
                                        ),
                                        tableCellBold(context, 'TONELADAS'),
                                      ],
                                    ),

                                    // Filas con datos
                                    for (
                                      int i = 0;
                                      i < _exploraciones.length;
                                      i++
                                    )
                                      TableRow(
                                        children: [
                                          tableCell((i + 1).toString()),
                                          tableCell(
                                            _exploraciones[i]['fecha']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          tableCell(
                                            _exploraciones[i]['turno']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          tableCell(
                                            _exploraciones[i]['empresa']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          tableCell(
                                            _exploraciones[i]['zona']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          tableCellMulti([
                                            _exploraciones[i]['tipo_labor']
                                                    ?.toString() ??
                                                '',
                                            _exploraciones[i]['labor']
                                                    ?.toString() ??
                                                '',
                                            _exploraciones[i]['ala']
                                                    ?.toString() ??
                                                '',
                                          ]),
                                          tableCell(
                                            _exploraciones[i]['veta']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          tableCell(
                                            _exploraciones[i]['tipo_perforacion']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          tableCell(
                                            _exploraciones[i]['toneladas']
                                                    ?.toString() ??
                                                '',
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              // Botones de acción
                              // Padding(
                              //   padding:
                              //       const EdgeInsets.symmetric(horizontal: 8.0),
                              //   child: Row(
                              //     mainAxisAlignment:
                              //         MainAxisAlignment.spaceEvenly,
                              //     children: [
                              //       ElevatedButton.icon(
                              //         style: ElevatedButton.styleFrom(
                              //           backgroundColor: Colors.red,
                              //           padding: EdgeInsets.symmetric(
                              //               horizontal: 16, vertical: 12),
                              //         ),
                              //         icon: Icon(Icons.delete, size: 18),
                              //         onPressed: () {

                              //         },
                              //         label: Text('BORRAR'),
                              //       ),
                              //       SizedBox(width: 10),
                              //       ElevatedButton.icon(
                              //         style: ElevatedButton.styleFrom(
                              //           backgroundColor: Colors.green,
                              //           padding: EdgeInsets.symmetric(
                              //               horizontal: 16, vertical: 12),
                              //         ),
                              //         icon: Icon(Icons.send, size: 18),
                              //         label: Text('ENVIAR'),
                              //         onPressed: () async {
                              //         await insertarYActualizarMedicionesLargo();
                              //         },
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> insertarYActualizarMedicionesLargo() async {
    List<Map<String, dynamic>> registros = obtenerDatosEditadosFormateados();

    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay registros con datos válidos (toneladas > 0)'),
        ),
      );
      return;
    }

    final dbHelper = DatabaseHelper();
    int registrosInsertados = 0;

    try {
      for (var registro in registros) {
        int idInsertado = await dbHelper.insertarMedicionLargo(registro);
        print("✅ Registro insertado con id: $idInsertado");
        registrosInsertados++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$registrosInsertados registros guardados exitosamente',
          ),
        ),
      );

      await _recargarDatos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar datos: ${e.toString()}')),
      );
      print("❌ Error al insertar/actualizar mediciones: $e");
    }
  }

  List<Map<String, dynamic>> obtenerDatosEditadosFormateados() {
    List<Map<String, dynamic>> listaDatos = [];

    for (var exploracion in _exploraciones) {
      double toneladas =
          double.tryParse(exploracion['toneladas']?.toString() ?? '0.0') ?? 0.0;

      // ✅ Cambio clave: Ahora verificamos específicamente que toneladas > 0
      // (kgExplosivos puede ser 0 o mayor)
      if (toneladas > 0) {
        String tipoLaborLaborAla = [
          exploracion['tipo_labor']?.toString() ?? '',
          exploracion['labor']?.toString() ?? '',
          exploracion['ala']?.toString() ?? '',
        ].where((part) => part.isNotEmpty).join(' ').trim();

        Map<String, dynamic> datos = {
          'id_explosivo': exploracion['id'],
          'fecha': exploracion['fecha'],
          'turno': exploracion['turno'],
          'empresa': exploracion['empresa'],
          'zona': exploracion['zona'],
          'labor': tipoLaborLaborAla,
          'veta': exploracion['veta'],
          'tipo_perforacion': exploracion['tipo_perforacion'],
          'toneladas': toneladas.toStringAsFixed(2),
          'idnube': exploracion['idnube'] ?? 0,
        };

        listaDatos.add(datos);
        print("✅ Registro válido agregado - Toneladas: $toneladas");
      } else {
        print("⛔ Registro omitido - Toneladas: $toneladas");
      }
    }

    return listaDatos;
  }

  Future<void> _recargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    // Limpia los datos existentes y los controladores
    _limpiarControladores();
    _exploracionesSucio = [];
    _exploraciones = [];
    registrosEditados = {};

    // Vuelve a cargar todos los datos
    await _getTiposPerforacion();
    await _cargarExploraciones();

    setState(() {
      _isLoading = false;
    });
  }

  void _limpiarControladores() {
    // Disponse de todos los controladores existentes
    controllers.forEach((key, controller) {
      controller.dispose();
    });
    // Limpia el mapa de controladores
    controllers.clear();
  }

  Widget tableCellMulti(List<String> texts, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: texts
            .map(
              (text) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void actualizarValor(
    String tipoPerforacion,
    String labor,
    int index,
    String campo,
    String nuevoValor,
  ) {
    setState(() {
      _exploraciones[index][campo] = nuevoValor;

      // Guarda la fila completa editada
      registrosEditados[index] = Map<String, dynamic>.from(
        _exploraciones[index],
      );
    });
  }

  Widget tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(child: Text(text)),
    );
  }

  Widget tableCellBold(BuildContext context, String text) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth < 600
        ? 8
        : 12; // Ajusta el umbral y tamaños a gusto

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
      ),
    );
  }
}
