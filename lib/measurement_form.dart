import 'package:flutter/material.dart';
import 'models/measurement.dart';
import 'db/database_helper.dart';

class MeasurementForm extends StatefulWidget {
  final Measurement? initialMeasurement;
  const MeasurementForm({super.key, this.initialMeasurement});

  @override
  State<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final _glicemiaController = TextEditingController();
  final _insulinaController = TextEditingController();
  final _observationsController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _glicemiaController.dispose();
    _insulinaController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final m = widget.initialMeasurement;
    if (m != null) {
      _selectedDate = m.date;
      _dateController.text = _formatDate(m.date);

      final parts = m.time.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
        _timeController.text = _formatTimeOfDay(_selectedTime!);
      }

      _glicemiaController.text = m.glicemia.toString();
      _insulinaController.text = m.insulina.toString();
      _observationsController.text = m.observations ?? '';
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = _formatDate(date);
      });
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final time = await showTimePicker(context: context, initialTime: now);
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _timeController.text = _formatTimeOfDay(time);
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final date = _selectedDate ?? DateTime.now();
    final timeOfDay = _selectedTime ?? TimeOfDay.now();
    final glicemia = int.parse(_glicemiaController.text);
    final insulina = double.parse(
      _insulinaController.text.replaceAll(',', '.'),
    );
    final observations = _observationsController.text.isEmpty
        ? null
        : _observationsController.text;

    final measurement = Measurement(
      id: widget.initialMeasurement?.id,
      date: date,
      time: _formatTimeOfDay(timeOfDay),
      glicemia: glicemia,
      insulina: insulina,
      observations: observations,
    );

    try {
      if (widget.initialMeasurement != null) {
        await DatabaseHelper.instance.updateMeasurement(measurement);
      } else {
        await DatabaseHelper.instance.insertMeasurement(measurement);
      }
    } catch (e, stacktrace) {
      if (!mounted) return;
      print('Error saving: $e');
      print('Stack trace: $stacktrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao guardar: $e')));
      return;
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dados guardados'),
        content: const Text('A medição foi guardada com sucesso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Medição')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Data'),
                      onTap: _pickDate,
                      validator: (v) =>
                          (_selectedDate == null || v == null || v.isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Hora'),
                      onTap: _pickTime,
                      validator: (v) =>
                          (_selectedTime == null || v == null || v.isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _glicemiaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Glicemia (mg/dL)',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final n = int.tryParse(v);
                  if (n == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _insulinaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Insulina administrada (UI)',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observationsController,
                keyboardType: TextInputType.text,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('Salvar')),
            ],
          ),
        ),
      ),
    );
  }
}
