import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/DimTurno.dart';
import 'package:i_miner/models/Equipo.dart';
import 'package:i_miner/models/tipo_horometro.dart';
import 'package:i_miner/screens/widgets/custom_dropdown.dart';
import 'package:i_miner/screens/widgets/operacion_card_config.dart';

class OperacionCard extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onOperacionCreada;
  final Function(String?) onTurnoChanged;
  final Function(String) onFechaChanged;
  final String? dniUsuario;
  final String? selectedOperatorName;
  final int? selectedOperatorId;
  final List<Map<String, dynamic>> operators;
  final bool canSelectOperators;
  final ValueChanged<int?>? onSelectedOperatorChanged;
  final Map<String, dynamic>? operacionExistente;

  final String fechaActual;
  final String? selectedTurno;

  final Color primaryColor;
  final OperacionCardConfig config;

  const OperacionCard({
    super.key,
    required this.onOperacionCreada,
    required this.onTurnoChanged,
    required this.onFechaChanged,
    required this.fechaActual,
    required this.selectedTurno,
    required this.operacionExistente,
    required this.config,
    this.dniUsuario,
    this.selectedOperatorName,
    this.selectedOperatorId,
    this.operators = const [],
    this.canSelectOperators = false,
    this.onSelectedOperatorChanged,
    this.primaryColor = const Color(0xFF1B5E6B),
  });

  @override
  State<OperacionCard> createState() => _OperacionCardState();
}

class _OperacionCardState extends State<OperacionCard> {
  final TextEditingController _equipoController = TextEditingController();
  final TextEditingController _jefeGuardiaController = TextEditingController();
  final FocusNode _equipoFocusNode = FocusNode();
  final FocusNode _jefeGuardiaFocusNode = FocusNode();

  String? selectedEquipo;
  String? selectedCodigo;
  String? selectedModelo;
  String? selectedJefeGuardia;
  String? selectedCapacidad;
  String? operador;
  int? operadorId;
  int? registradorUsuarioId;
  String? registradorNombre;
  bool _loadingEquipos = true;
  bool _loadingJefesGuardia = true;

  bool get operacionBloqueada => widget.operacionExistente != null;

  final String operadorEjemplo = 'Juan Pérez';

  List<String> turnos = [];

  List<String> equipos = [];
  List<String> jefesGuardia = [];
  final Map<String, int> jefeGuardiaIdPorNombre = {};
  final Map<String, List<String>> codigosPorEquipo = {};
  final Map<String, List<String>> modelosPorCodigo = {};
  final Map<String, String> capacidadPorCodigo = {};

  final Map<String, Equipo> _equipoLabelMap = {};
  List<Equipo> equiposCompletos = [];
  List<String> codigosFiltrados = [];
  List<String> modelosFiltrados = [];
  List<String> capacidadesFiltradas = [];

  List<TipoHorometro> tiposEquipo = [];
  Map<int, bool> tiposSeleccionados = {};
  List<DimTurno> turnosCatalogo = [];

  @override
  void initState() {
    super.initState();
    _cargarOperadorPorDni();
    _cargarEquipos();
    _cargarJefesGuardia();
    _cargarTurnosCatalogo();
    if (widget.config.mostrarTipoEquipo) _cargarTiposEquipo();

    if (widget.operacionExistente != null) {
      _restoreFromExisting(widget.operacionExistente!);
    }
  }

  void _restoreFromExisting(Map<String, dynamic> op) {
    selectedEquipo = op['equipo'];
    selectedCodigo = op['n_equipo'];
    if (widget.config.mostrarModelo) {
      selectedModelo = op['modelo_equipo'] ?? op['modelo'];
    }
    selectedJefeGuardia = op['jefe_guardia'];
    if (widget.config.mostrarCapacidad) selectedCapacidad = op['capacidad'];

    _equipoController.text = op['equipo']?.toString() ?? '';
    _jefeGuardiaController.text = selectedJefeGuardia ?? '';

    codigosFiltrados = codigosPorEquipo[selectedEquipo] ?? [];
    if (selectedCodigo != null) {
      if (widget.config.mostrarModelo) {
        _actualizarModelosPorCodigo(selectedCodigo);
      }
      if (widget.config.mostrarCapacidad &&
          capacidadPorCodigo.containsKey(selectedCodigo)) {
        selectedCapacidad = capacidadPorCodigo[selectedCodigo];
      }
    }
  }

  @override
  void dispose() {
    _equipoController.dispose();
    _jefeGuardiaController.dispose();
    _equipoFocusNode.dispose();
    _jefeGuardiaFocusNode.dispose();
    super.dispose();
  }

  void _syncDisplayedOperator({String? fallbackName}) {
    operador = widget.selectedOperatorName ?? fallbackName ?? operadorEjemplo;
  }

  String _equipoLabel(Equipo e) =>
      '${e.codigo} | ${e.nombre} ${e.modelo}'.trim();

  String _equipoDisplayLabel() {
    if (selectedCodigo == null || selectedEquipo == null) return '';
    for (final entry in _equipoLabelMap.entries) {
      if (entry.value.codigo == selectedCodigo) return entry.key;
    }
    return '$selectedCodigo | $selectedEquipo ${selectedModelo ?? ''}'.trim();
  }

  String _operatorLabel(Map<String, dynamic> operator) {
    final dni = operator['codigo_dni']?.toString() ?? '';
    final nombres = operator['nombres']?.toString() ?? '';
    final apellidos = operator['apellidos']?.toString() ?? '';
    final label = '$apellidos $nombres'.trim();
    return dni.isEmpty ? label : '$label - $dni';
  }

  Map<String, dynamic>? _selectedOperator() {
    for (final operator in widget.operators) {
      if (operator['id'] == widget.selectedOperatorId) {
        return operator;
      }
    }
    return null;
  }

  Future<void> _cargarOperadorPorDni() async {
    if (widget.dniUsuario == null) return;

    try {
      final dbHelper = DatabaseHelper();
      final usuario = await dbHelper.getUserByDni(widget.dniUsuario!);

      if (usuario != null) {
        setState(() {
          operadorId = usuario['id'] as int?;
          registradorUsuarioId = usuario['id'] as int?;
          registradorNombre = '${usuario['nombres']} ${usuario['apellidos']}'
              .trim();
          _syncDisplayedOperator(
            fallbackName: '${usuario['nombres']} ${usuario['apellidos']}',
          );
        });
      } else {
        setState(() {
          _syncDisplayedOperator();
          operadorId = null;
          registradorUsuarioId = null;
          registradorNombre = null;
        });
      }
    } catch (e) {
      setState(() {
        _syncDisplayedOperator();
        operadorId = null;
        registradorUsuarioId = null;
        registradorNombre = null;
      });
    }
  }

  Future<void> _cargarTurnosCatalogo() async {
    try {
      final dbHelper = DatabaseHelper();
      final turnosDb = await dbHelper.getDimTurnos();
      if (!mounted) return;

      setState(() {
        turnosCatalogo = turnosDb;
        if (turnosDb.isNotEmpty) {
          turnos = turnosDb.map((t) => t.nombre).toList();
        }
      });

      final turnoActual = _resolverNombreTurno(widget.selectedTurno);
      if (!operacionBloqueada &&
          widget.selectedTurno != null &&
          turnoActual != null &&
          turnoActual != widget.selectedTurno) {
        widget.onTurnoChanged(turnoActual);
      }
    } catch (_) {
      // Mantener fallback DÍA/NOCHE si el catálogo no está disponible.
    }
  }

  Future<void> _cargarEquipos() async {
    try {
      codigosPorEquipo.clear();
      modelosPorCodigo.clear();
      capacidadPorCodigo.clear();

      final dbHelper = DatabaseHelper();
      equiposCompletos = await dbHelper.getEquipos();
      equiposCompletos =
          equiposCompletos
              .where((e) => e.matchesProceso(widget.config.proceso))
              .toList()
            ..sort((a, b) => a.nombre.compareTo(b.nombre));

      Set<String> nombresEquipos = {};

      for (var equipo in equiposCompletos) {
        nombresEquipos.add(equipo.nombre);

        codigosPorEquipo.putIfAbsent(equipo.nombre, () => []);
        if (!codigosPorEquipo[equipo.nombre]!.contains(equipo.codigo)) {
          codigosPorEquipo[equipo.nombre]!.add(equipo.codigo);
        }

        if (widget.config.mostrarModelo) {
          modelosPorCodigo.putIfAbsent(equipo.codigo, () => []);
          if (!modelosPorCodigo[equipo.codigo]!.contains(equipo.modelo)) {
            modelosPorCodigo[equipo.codigo]!.add(equipo.modelo);
          }
        }

        if (widget.config.mostrarCapacidad) {
          double capacidadValor = equipo.capacidadYd3 ?? 0;
          String capacidadString;
          if (capacidadValor == capacidadValor.floorToDouble()) {
            capacidadString = capacidadValor.toInt().toString();
          } else {
            capacidadString = capacidadValor.toStringAsFixed(2);
          }
          capacidadPorCodigo[equipo.codigo] = capacidadString;
        }
      }

      _equipoLabelMap.clear();
      for (var equipo in equiposCompletos) {
        _equipoLabelMap[_equipoLabel(equipo)] = equipo;
      }

      setState(() {
        _loadingEquipos = false;
        equipos = nombresEquipos.toList()..sort();

        if (selectedEquipo != null) {
          codigosFiltrados = codigosPorEquipo[selectedEquipo] ?? [];
        }
        if (selectedCodigo != null) {
          if (widget.config.mostrarModelo) {
            modelosFiltrados = modelosPorCodigo[selectedCodigo] ?? [];
          }
          if (widget.config.mostrarCapacidad &&
              capacidadPorCodigo.containsKey(selectedCodigo)) {
            selectedCapacidad = capacidadPorCodigo[selectedCodigo];
          }
        }
        if (!operacionBloqueada) {
          _equipoController.text = _equipoDisplayLabel();
        }
      });
    } catch (e) {
      setState(() {
        _loadingEquipos = false;
        equipos = [];
        codigosFiltrados = [];
        modelosFiltrados = [];
      });
    }
  }

  Future<void> _cargarJefesGuardia() async {
    try {
      final dbHelper = DatabaseHelper();
      final jefes = await dbHelper.getJefesGuardia();
      final idsPorNombre = <String, int>{};
      final nombres = jefes.map((j) {
        final nombre = '${j.nombres} ${j.apellidos}'.trim();
        idsPorNombre[nombre] = j.id;
        return nombre;
      }).toList();

      setState(() {
        _loadingJefesGuardia = true;
        jefeGuardiaIdPorNombre
          ..clear()
          ..addAll(idsPorNombre);
        jefesGuardia = nombres..sort();
        _loadingJefesGuardia = false;
      });
    } catch (e) {
      setState(() {
        _loadingJefesGuardia = false;
        jefeGuardiaIdPorNombre.clear();
        jefesGuardia = [];
      });
    }
  }

  int? _resolverTurnoId(String? turnoNombre) {
    return _resolverTurnoCatalogo(turnoNombre)?.turnoId;
  }

  DimTurno? _resolverTurnoCatalogo(String? turnoNombre) {
    if (turnoNombre == null) return null;
    final buscado = _normalizarClave(turnoNombre);

    for (final turno in turnosCatalogo) {
      if (_normalizarClave(turno.nombre) == buscado ||
          _normalizarClave(turno.codigo) == buscado) {
        return turno;
      }
    }
    return null;
  }

  String? _resolverNombreTurno(String? turnoNombre) {
    final turno = _resolverTurnoCatalogo(turnoNombre);
    return turno?.nombre ?? turnoNombre;
  }

  String _normalizarClave(String? value) {
    if (value == null) return '';
    const replacements = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'á': 'A',
      'é': 'E',
      'í': 'I',
      'ó': 'O',
      'ú': 'U',
      'ü': 'U',
    };
    final buffer = StringBuffer();
    for (final rune in value.trim().runes) {
      buffer.write(
        replacements[String.fromCharCode(rune)] ?? String.fromCharCode(rune),
      );
    }
    return buffer.toString().toUpperCase();
  }

  Future<void> _cargarTiposEquipo() async {
    try {
      final dbHelper = DatabaseHelper();
      final tipos = await dbHelper.getTiposHorometro();

      setState(() {
        tiposEquipo = tipos;
        tiposSeleccionados.clear();
        for (var tipo in tiposEquipo) {
          if (tipo.id != null) {
            tiposSeleccionados[tipo.id!] = false;
          }
        }
      });

      if (widget.operacionExistente != null) {
        final tipoEquipoStr =
            widget.operacionExistente!['tipo_equipo'] as String?;
        if (tipoEquipoStr != null && tipoEquipoStr.isNotEmpty) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(tipoEquipoStr);
            for (var tipo in tiposEquipo) {
              if (tipo.id != null && decoded.containsKey(tipo.nombre)) {
                tiposSeleccionados[tipo.id!] = decoded[tipo.nombre] as bool;
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      print('Error cargando tipos equipo: $e');
    }
  }

  @override
  void didUpdateWidget(covariant OperacionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.operacionExistente != oldWidget.operacionExistente) {
      if (widget.operacionExistente != null) {
        _restoreFromExisting(widget.operacionExistente!);
      } else {
        selectedEquipo = null;
        selectedCodigo = null;
        selectedModelo = null;
        selectedJefeGuardia = null;
        selectedCapacidad = null;
        codigosFiltrados = [];
        modelosFiltrados = [];
        _equipoController.clear();
        _jefeGuardiaController.clear();
      }
      setState(() {});
    }

    if (oldWidget.selectedOperatorId != widget.selectedOperatorId ||
        oldWidget.selectedOperatorName != widget.selectedOperatorName) {
      setState(() {
        _syncDisplayedOperator();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadingEquipos || _loadingJefesGuardia)
              const LinearProgressIndicator(),
            _buildFormFields(),
            if (widget.config.mostrarTipoEquipo) _buildTipoEquipoField(),
            const SizedBox(height: 20),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    final turnoSeleccionado = _resolverNombreTurno(widget.selectedTurno);

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = constraints.maxWidth;

        Map<String, double> fieldWeights = {
          'fecha': 0.8,
          'turno': 0.7,
          'equipo': 1.5,
          'operador': 1.7,
          'jefe': 1.7,
        };
        if (widget.config.mostrarCapacidad) fieldWeights['capacidad'] = 0.7;

        double scaleFactor = cardWidth > 900
            ? 1.0
            : cardWidth > 700
            ? 0.9
            : cardWidth > 500
            ? 0.8
            : 0.7;

        return Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            _buildFlexibleField(
              width: _calculateFieldWidth(
                cardWidth,
                fieldWeights['fecha']! * scaleFactor,
                fieldWeights,
              ),
              child: _buildFechaField(),
            ),
            _buildFlexibleField(
              width: _calculateFieldWidth(
                cardWidth,
                fieldWeights['turno']! * scaleFactor,
                fieldWeights,
              ),
              child: SizedBox(
                height: 45,
                child: CustomMaterialDropdown(
                  label: 'Turno',
                  value: turnoSeleccionado,
                  items: turnos,
                  onChanged: operacionBloqueada ? null : widget.onTurnoChanged,
                  icon: Icons.access_time,
                  hint: 'Turno',
                  primaryColor: widget.primaryColor,
                ),
              ),
            ),
            _buildFlexibleField(
              width: _calculateFieldWidth(
                cardWidth,
                fieldWeights['equipo']! * scaleFactor,
                fieldWeights,
              ),
              child: RawAutocomplete<String>(
                textEditingController: _equipoController,
                focusNode: _equipoFocusNode,
                optionsBuilder: (textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  if (query.isEmpty) return _equipoLabelMap.keys.toList();
                  return _equipoLabelMap.keys.where(
                    (label) => label.toLowerCase().contains(query),
                  );
                },
                onSelected: operacionBloqueada
                    ? null
                    : (label) {
                        final equipo = _equipoLabelMap[label];
                        if (equipo == null) return;
                        setState(() {
                          selectedEquipo = equipo.nombre;
                          selectedCodigo = equipo.codigo;
                          selectedModelo = equipo.modelo.isNotEmpty
                              ? equipo.modelo
                              : null;
                          if (widget.config.mostrarCapacidad) {
                            selectedCapacidad =
                                capacidadPorCodigo[equipo.codigo] ?? '';
                          }
                          _equipoController.text = label;
                        });
                      },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: !operacionBloqueada,
                        onChanged: (value) {
                          setState(() {
                            selectedEquipo = null;
                            selectedCodigo = null;
                            selectedModelo = null;
                            selectedCapacidad = null;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Equipo',
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          prefixIcon: Icon(
                            Icons.precision_manufacturing,
                            size: 16,
                            color: widget.primaryColor,
                          ),
                          hintText: _equipoLabelMap.isEmpty
                              ? 'Cargando...'
                              : 'Buscar equipo...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: widget.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
                        width: 450,
                        height: 240,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final label = options.elementAt(index);
                            final equipo = _equipoLabelMap[label];
                            return ListTile(
                              dense: true,
                              title: Text(
                                label,
                                style: const TextStyle(fontSize: 12),
                              ),
                              subtitle: equipo != null
                                  ? Text(
                                      '${equipo.marca} · ${equipo.proceso}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    )
                                  : null,
                              onTap: () => onSelected(label),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.config.mostrarCapacidad)
              _buildFlexibleField(
                width: _calculateFieldWidth(
                  cardWidth,
                  fieldWeights['capacidad']! * scaleFactor,
                  fieldWeights,
                ),
                child: _buildCapacidadField(),
              ),
            _buildFlexibleField(
              width: _calculateFieldWidth(
                cardWidth,
                fieldWeights['operador']! * scaleFactor,
                fieldWeights,
              ),
              child: _buildOperadorField(),
            ),
            _buildFlexibleField(
              width: _calculateFieldWidth(
                cardWidth,
                fieldWeights['jefe']! * scaleFactor,
                fieldWeights,
              ),
              child: RawAutocomplete<String>(
                textEditingController: _jefeGuardiaController,
                focusNode: _jefeGuardiaFocusNode,
                optionsBuilder: (textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  if (query.isEmpty) return jefesGuardia;
                  return jefesGuardia.where(
                    (label) => label.toLowerCase().contains(query),
                  );
                },
                onSelected: operacionBloqueada
                    ? null
                    : (value) => setState(() {
                        selectedJefeGuardia = value;
                        _jefeGuardiaController.text = value;
                      }),
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: !operacionBloqueada,
                        onChanged: (value) {
                          setState(() => selectedJefeGuardia = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'Jefe Guardia',
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          prefixIcon: Icon(
                            Icons.person,
                            size: 16,
                            color: widget.primaryColor,
                          ),
                          hintText: jefesGuardia.isEmpty
                              ? 'Cargando...'
                              : 'Buscar jefe guardia...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: widget.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
                        width: 350,
                        height: 240,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final label = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              title: Text(
                                label,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () => onSelected(label),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipoEquipoField() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de equipo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: tiposEquipo.map((tipo) {
              final isSelected =
                  tipo.id != null && (tiposSeleccionados[tipo.id!] ?? false);
              return InkWell(
                onTap: operacionBloqueada
                    ? null
                    : () {
                        setState(() {
                          if (tipo.id != null) {
                            tiposSeleccionados[tipo.id!] = !isSelected;
                          }
                        });
                      },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? widget.primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 16,
                        color: isSelected
                            ? widget.primaryColor
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tipo.nombre,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: isSelected
                              ? widget.primaryColor
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacidadField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Capacidad (yd³)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  selectedCapacidad ?? '-',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selectedCapacidad != null
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.straighten, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildFlexibleField({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }

  Widget _buildFechaField() {
    bool isEnabled = !operacionBloqueada;

    return InkWell(
      onTap: isEnabled ? _selectDate : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEnabled
                ? widget.primaryColor.withValues(alpha: 0.5)
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isEnabled ? Colors.white : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fecha',
                    style: TextStyle(
                      fontSize: 11,
                      color: isEnabled ? widget.primaryColor : Colors.grey,
                    ),
                  ),
                  Text(
                    widget.fechaActual,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isEnabled ? Colors.black87 : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: isEnabled ? widget.primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperadorField() {
    if (widget.canSelectOperators) {
      final selectedOperator = _selectedOperator();
      final initialLabel = selectedOperator != null
          ? _operatorLabel(selectedOperator)
          : '';
      final operatorLabels = widget.operators.map(_operatorLabel).toList();

      return RawAutocomplete<String>(
        initialValue: TextEditingValue(text: initialLabel),
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) return operatorLabels;
          return operatorLabels.where(
            (label) => label.toLowerCase().contains(query),
          );
        },
        onSelected: widget.operators.isEmpty || operacionBloqueada
            ? null
            : (label) {
                for (final op in widget.operators) {
                  if (_operatorLabel(op) == label) {
                    widget.onSelectedOperatorChanged?.call(op['id'] as int?);
                    break;
                  }
                }
              },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !operacionBloqueada,
            onChanged: (value) {
              widget.onSelectedOperatorChanged?.call(null);
            },
            decoration: InputDecoration(
              labelText: 'Operador',
              labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
              prefixIcon: Icon(
                Icons.person_outline,
                size: 16,
                color: widget.primaryColor,
              ),
              hintText: widget.operators.isEmpty
                  ? 'Aun no hay operadores conocidos en este dispositivo'
                  : 'Buscar operador...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
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
                width: 400,
                height: 240,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final label = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(label, style: const TextStyle(fontSize: 12)),
                      onTap: () => onSelected(label),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Operador',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  operador ?? operadorEjemplo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.person_outline, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: operacionBloqueada ? null : _crearOperacion,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 16),
            SizedBox(width: 6),
            Text(
              'CREAR OPERACIÓN',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateFieldWidth(
    double totalWidth,
    double weight,
    Map<String, double> weights,
  ) {
    double totalWeights = weights.values.fold(0, (sum, w) => sum + w);
    double spacing = 10 * (weights.length - 1);
    double padding = 16 * 2;
    double availableWidth = totalWidth - spacing - padding;
    return (availableWidth * weight) / totalWeights;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.fechaActual),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      String nuevaFecha = DateFormat('yyyy-MM-dd').format(picked);

      if (nuevaFecha != widget.fechaActual) {
        widget.onFechaChanged(nuevaFecha);
      }
    }
  }

  Future<void> _crearOperacion() async {
    if (widget.selectedTurno == null ||
        selectedEquipo == null ||
        selectedCodigo == null ||
        selectedJefeGuardia == null) {
      _showSnackbar('Complete todos los campos', Colors.orange);
      return;
    }

    if (widget.config.mostrarModelo && selectedModelo == null) {
      _showSnackbar('Seleccione el modelo', Colors.orange);
      return;
    }

    if (widget.config.mostrarCapacidad && selectedCapacidad == null) {
      _showSnackbar('Seleccione un equipo con capacidad', Colors.orange);
      return;
    }

    if (widget.config.mostrarTipoEquipo) {
      bool algunTipoSeleccionado = tiposSeleccionados.values.contains(true);
      if (!algunTipoSeleccionado) {
        _showSnackbar('Seleccione al menos un tipo de equipo', Colors.orange);
        return;
      }
    }

    int? equipoId;
    final match = equiposCompletos.firstWhere(
      (e) => e.nombre == selectedEquipo && e.codigo == selectedCodigo,
      orElse: () => Equipo(
        nombre: '',
        proceso: '',
        codigo: '',
        marca: '',
        modelo: '',
        serie: '',
        anioFabricacion: 0,
        fechaIngreso: '',
      ),
    );
    equipoId = match.id;

    String? tiposJsonString;
    final turnoNombre = _resolverNombreTurno(widget.selectedTurno);
    final turnoId = _resolverTurnoId(turnoNombre);
    final jefeGuardiaId = jefeGuardiaIdPorNombre[selectedJefeGuardia];
    final equipoSnapshot = widget.config.mostrarModelo && selectedModelo != null
        ? '$selectedEquipo $selectedModelo'
        : selectedEquipo;
    if (widget.config.mostrarTipoEquipo) {
      Map<String, bool> tiposMap = {};
      for (var tipo in tiposEquipo) {
        if (tipo.id != null) {
          tiposMap[tipo.nombre] = tiposSeleccionados[tipo.id!] ?? false;
        }
      }
      tiposJsonString = jsonEncode(tiposMap);
    }

    Map<String, dynamic> data = {
      'equipo_id': equipoId,
      'turno_id': turnoId,
      'actor_operador_id': operadorId,
      'operador_id': widget.selectedOperatorId ?? operadorId,
      'registrador_id': registradorUsuarioId,
      'jefe_guardia_id': jefeGuardiaId,
      'fecha': widget.fechaActual,
    };

    data['turno'] = turnoNombre;
    data['equipo'] = equipoSnapshot;
    data[widget.config.claveCodigo] = selectedCodigo;
    data['operador'] = operador ?? operadorEjemplo;
    data['actor_dni'] = widget.dniUsuario;
    data['registrador'] = registradorNombre;
    data['jefe_guardia'] = selectedJefeGuardia;
    data['jefeGuardia'] = selectedJefeGuardia;
    data[widget.config.claveJefeGuardia] = selectedJefeGuardia;

    if (widget.config.mostrarModelo && selectedModelo != null) {
      data['modelo'] = selectedModelo;
    }
    if (widget.config.mostrarCapacidad && selectedCapacidad != null) {
      data['capacidad'] = selectedCapacidad;
    }
    if (tiposJsonString != null) {
      data['tipo_equipo'] = tiposJsonString;
    }

    await widget.onOperacionCreada(data);

    if (mounted) {
      setState(() {
        selectedEquipo = null;
        selectedCodigo = null;
        selectedModelo = null;
        selectedJefeGuardia = null;
        selectedCapacidad = null;
        codigosFiltrados = [];
        modelosFiltrados = [];
        _equipoController.clear();
        _jefeGuardiaController.clear();
      });
    }
  }

  void _actualizarModelosPorCodigo(String? codigo) {
    if (codigo != null && modelosPorCodigo.containsKey(codigo)) {
      modelosFiltrados = modelosPorCodigo[codigo]!;
    } else {
      modelosFiltrados = [];
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
