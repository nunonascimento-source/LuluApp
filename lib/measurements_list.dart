import 'package:flutter/material.dart';
import 'models/measurement.dart';
import 'db/database_helper.dart';
import 'measurement_form.dart';

class MeasurementsListPage extends StatefulWidget {
  const MeasurementsListPage({super.key});

  @override
  State<MeasurementsListPage> createState() => _MeasurementsListPageState();
}

class _MeasurementsListPageState extends State<MeasurementsListPage> {
  late Future<List<Measurement>> _measurementsFuture;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _reload() {
    setState(() {
      _measurementsFuture = DatabaseHelper.instance.getAllMeasurements();
    });
  }

  @override
  void initState() {
    super.initState();
    _measurementsFuture = DatabaseHelper.instance.getAllMeasurements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medições realizadas'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Measurement>>(
        future: _measurementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma medição realizada ainda'));
          }

          final measurements = snapshot.data!;

          // Group by date (Y-M-D)
          final Map<DateTime, List<Measurement>> grouped = {};
          for (final m in measurements) {
            final key = DateTime(m.date.year, m.date.month, m.date.day);
            grouped.putIfAbsent(key, () => []).add(m);
          }

          // Sort dates ascending (older first)
          final dates = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final items = grouped[date]!;
              // Sort items by time ascending
              items.sort((a, b) => a.time.compareTo(b.time));

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(
                    _formatDate(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: items.map((m) {
                    final hasId = m.id != null;
                    return ListTile(
                      title: Text(
                        'Glicemia: ${m.glicemia} mg/dL',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Insulina: ${m.insulina.toStringAsFixed(2)} UI'),
                          Text('Hora: ${m.time}'),
                          if (m.observations != null &&
                              m.observations!.isNotEmpty)
                            Text('Observações: ${m.observations}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Editar',
                            onPressed: hasId
                                ? () async {
                                    final updated = await Navigator.push<bool?>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MeasurementForm(
                                          initialMeasurement: m,
                                        ),
                                      ),
                                    );
                                    if (updated == true) {
                                      _reload();
                                    }
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Apagar',
                            onPressed: hasId
                                ? () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Apagar medição'),
                                        content: const Text(
                                          'Tem certeza de que deseja apagar esta medição?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Apagar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await DatabaseHelper.instance
                                          .deleteMeasurement(m.id!);
                                      _reload();
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
