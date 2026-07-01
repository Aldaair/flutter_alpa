import 'package:flutter/material.dart';
import 'package:i_miner/config/data/database_helper.dart';

class RegistroOperacionDialog extends StatefulWidget {
  final String turno;
  final String selectedState;
  final int procesoId;
  final int categoriaId;
  final Map<String, String>? existingRecord;
  final String? ultimaHoraRegistrada;
  final Function(Map<String, dynamic>) onConfirm;

  const RegistroOperacionDialog({
    super.key,
    required this.turno,
    required this.selectedState,
    required this.procesoId,
    required this.categoriaId,
    this.existingRecord,
    this.ultimaHoraRegistrada,
    required this.onConfirm,
  });

  @override
  State<RegistroOperacionDialog> createState() =>
      _RegistroOperacionDialogState();
}

class _RegistroOperacionDialogState extends State<RegistroOperacionDialog> {
  String? selectedCodigo;
  String? selectedTime;
  late bool isEditing;
  List<Map<String, dynamic>> _estadosCatalogo = [];
  bool _loadingEstados = true;

  @override
  void initState() {
    super.initState();
    isEditing = widget.existingRecord != null;

    if (isEditing && widget.existingRecord != null) {
      selectedCodigo = widget.existingRecord!['codigo'];
      selectedTime = widget.existingRecord!['hora_inicio'];
    }

    _cargarEstados();
  }

  Future<void> _cargarEstados() async {
    print(
      "🔍 _cargarEstados: procesoId=${widget.procesoId}, categoriaId=${widget.categoriaId}",
    );
    final estados = await DatabaseHelper().getEstadosByProcesoAndCategoria(
      widget.procesoId,
      widget.categoriaId,
    );
    print("🔍 _cargarEstados: encontrados ${estados.length} estados");
    if (!mounted) return;
    setState(() {
      _estadosCatalogo = estados;
      _loadingEstados = false;
    });
  }

  int _convertToShiftMinutes(String time) {
    final parts = time.split(':').map(int.parse).toList();
    int hour = parts[0];
    int minute = parts[1];

    int totalMinutes = hour * 60 + minute;

    if (widget.turno != "DÍA") {
      if (hour < 7) {
        totalMinutes += 24 * 60;
      }
    }

    return totalMinutes;
  }

  int _compareTimes(String time1, String time2) {
    try {
      return _convertToShiftMinutes(time1) - _convertToShiftMinutes(time2);
    } catch (e) {
      return 0;
    }
  }

  List<String> _generateTimeIntervals(String turno) {
    List<String> times = [];

    if (turno == "DÍA") {
      for (int hour = 7; hour <= 17; hour++) {
        for (int minute = 0; minute < 60; minute += 5) {
          if (hour == 17 && minute > 25) break;
          times.add(
            "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
          );
        }
      }
    } else {
      for (int hour = 19; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 5) {
          times.add(
            "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
          );
        }
      }

      for (int hour = 0; hour <= 5; hour++) {
        for (int minute = 0; minute < 60; minute += 5) {
          if (hour == 5 && minute > 25) break;
          times.add(
            "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
          );
        }
      }
    }

    return times;
  }

  List<String> _getValidTimeRangeForEdit(
    List<Map<String, dynamic>> codigoOperativos,
  ) {
    if (!isEditing || widget.existingRecord == null) return [];

    String? minTime = widget.existingRecord!['prev_hora_inicio'];
    String? maxTime = widget.existingRecord!['next_hora_inicio'];

    if ((minTime != null && minTime.isNotEmpty) ||
        (maxTime != null && maxTime.isNotEmpty)) {
      if (minTime?.contains(' ') == true) {
        minTime = minTime!.split(' ')[1];
      }
      if (maxTime?.contains(' ') == true) {
        maxTime = maxTime!.split(' ')[1];
      }

      final allTimes = _generateTimeIntervals(widget.turno);
      return allTimes.where((time) {
        if (minTime != null && minTime!.isNotEmpty &&
            _compareTimes(time, minTime!) <= 0) {
          return false;
        }
        if (maxTime != null && maxTime!.isNotEmpty &&
            _compareTimes(time, maxTime!) >= 0) {
          return false;
        }
        return true;
      }).toList();
    }

    int currentIndex = codigoOperativos.indexWhere(
      (item) => item["id"].toString() == widget.existingRecord!["id"],
    );

    if (currentIndex == -1) return [];

    String? fallbackMinTime;
    String? fallbackMaxTime;

    if (currentIndex > 0) {
      fallbackMinTime = codigoOperativos[currentIndex - 1]["hora_inicio"]?.toString();
      if (fallbackMinTime?.contains(' ') == true) {
        fallbackMinTime = fallbackMinTime!.split(' ')[1];
      }
    }

    if (currentIndex < codigoOperativos.length - 1) {
      fallbackMaxTime = codigoOperativos[currentIndex + 1]["hora_inicio"]?.toString();
      if (fallbackMaxTime?.contains(' ') == true) {
        fallbackMaxTime = fallbackMaxTime!.split(' ')[1];
      }
    }

    List<String> allTimes = _generateTimeIntervals(widget.turno);

    return allTimes.where((time) {
      if (fallbackMinTime != null && _compareTimes(time, fallbackMinTime) <= 0) {
        return false;
      }
      if (fallbackMaxTime != null && _compareTimes(time, fallbackMaxTime) >= 0) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _isValidTimeForShift(String time, String shift) {
    try {
      final hour = int.parse(time.split(':')[0]);
      final minute = int.parse(time.split(':')[1]);
      if (shift == "DÍA") {
        if (hour < 7 || hour > 18) return false;
        if (hour == 18 && minute > 55) return false;
      } else {
        if (hour > 6 && hour < 19) return false;
        if (hour == 6 && minute > 55) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  List<DropdownMenuItem<String>> _obtenerOpcionesUnicas() {
    final seen = <String>{};
    return _estadosCatalogo
        .where((e) => seen.add(e["codigo"] as String? ?? ""))
        .map((e) {
          String codigo = e["codigo"] as String? ?? "";
          String tipoEstado = e["tipo_estado"] as String? ?? "";
          return DropdownMenuItem<String>(
            value: codigo,
            child: Text(
              "$codigo - $tipoEstado",
              style: const TextStyle(fontSize: 14),
            ),
          );
        })
        .toList();
  }

  bool _validateSelection(List<Map<String, dynamic>> codigoOperativos) {
    if (selectedCodigo == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Faltan datos por seleccionar."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    bool horaExiste = codigoOperativos
        .where(
          (item) =>
              !isEditing ||
              item["id"].toString() != widget.existingRecord!["id"],
        )
        .any((item) {
          String horaItem = item["hora_inicio"]?.toString() ?? '';
          if (horaItem.contains(' ')) horaItem = horaItem.split(' ')[1];
          return horaItem == selectedTime;
        });

    if (horaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: La Hora Inicio ya está registrada."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    if (!_isValidTimeForShift(selectedTime!, widget.turno)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("La hora no está dentro del turno ${widget.turno}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    if (isEditing &&
        !_getValidTimeRangeForEdit(codigoOperativos).contains(selectedTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "La hora debe estar entre el registro anterior y el siguiente",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    if (!isEditing && widget.ultimaHoraRegistrada != null) {
      if (_compareTimes(selectedTime!, widget.ultimaHoraRegistrada!) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "La hora debe ser posterior a la última registrada (${widget.ultimaHoraRegistrada})",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }

    return true;
  }

  void _handleConfirm(List<Map<String, dynamic>> codigoOperativos) {
    if (!_validateSelection(codigoOperativos)) return;

    final editingId = isEditing
        ? int.tryParse(widget.existingRecord!['id'] ?? '')
        : null;
    final editingNumero = isEditing
        ? int.tryParse(widget.existingRecord!['numero'] ?? '')
        : null;

    final data = {
      'codigo': selectedCodigo,
      'hora_inicio': selectedTime,
      'estado': widget.selectedState,
      if (isEditing && editingId != null) 'id': editingId,
      if (isEditing && editingNumero != null) 'numero': editingNumero,
      if (isEditing) 'hora_final': widget.existingRecord!['hora_final'],
    };

    widget.onConfirm(data);
  }

  void _handleClear() {
    setState(() {
      if (widget.existingRecord != null) {
        selectedCodigo = widget.existingRecord!['codigo'];
        selectedTime = widget.existingRecord!['hora_inicio'];
      } else {
        selectedCodigo = null;
        selectedTime = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingEstados) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    List<String> timeOptions = _generateTimeIntervals(widget.turno);

    List<String> availableTimeOptions;

    if (isEditing) {
      availableTimeOptions = _getValidTimeRangeForEdit(_estadosCatalogo);
      if (selectedTime != null &&
          !availableTimeOptions.contains(selectedTime)) {
        availableTimeOptions = List.from(availableTimeOptions)
          ..add(selectedTime!);
        availableTimeOptions.sort((a, b) => _compareTimes(a, b));
      }
    } else {
      availableTimeOptions = timeOptions.where((hora) {
        if (!_isValidTimeForShift(hora, widget.turno)) return false;

        if (widget.ultimaHoraRegistrada != null) {
          return _compareTimes(hora, widget.ultimaHoraRegistrada!) > 0;
        }

        return true;
      }).toList();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Center(
        child: Column(
          children: [
            Text(
              isEditing ? "EDITAR OPERACIÓN" : "REGISTRAR OPERACIÓN",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!isEditing && widget.ultimaHoraRegistrada != null) ...[
              const SizedBox(height: 4),
              Text(
                "Última hora: ${widget.ultimaHoraRegistrada}",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estado: ${widget.selectedState}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Código (*)",
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedCodigo,
                items: _obtenerOpcionesUnicas(),
                onChanged: (value) {
                  setState(() {
                    selectedCodigo = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Hora Inicio (*)",
                  hintText: widget.ultimaHoraRegistrada != null && !isEditing
                      ? "Seleccione > ${widget.ultimaHoraRegistrada}"
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 12,
                  ),
                  border: const OutlineInputBorder(),
                ),
                initialValue: selectedTime,
                items: availableTimeOptions
                    .map(
                      (time) => DropdownMenuItem(
                        value: time,
                        child: Text(time, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTime = value;
                  });
                },
                menuMaxHeight: 200,
              ),
              if (!isEditing && widget.ultimaHoraRegistrada != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Solo horas posteriores a ${widget.ultimaHoraRegistrada}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleClear,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Limpiar"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleConfirm(_estadosCatalogo),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditing
                            ? Colors.orange
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(isEditing ? "Actualizar" : "Crear"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "(*) Los campos con asterisco son obligatorios.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
