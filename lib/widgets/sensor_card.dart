import 'package:flutter/material.dart';

import '../models/sensor.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.sensor,
    required this.events,
    required this.paused,
  });

  final SensorDefinition sensor;
  final Stream<SensorEvent> events;
  final bool paused;

  IconData get _icon => switch (sensor.kind) {
        SensorKind.temperature => Icons.thermostat_outlined,
        SensorKind.humidity => Icons.water_drop_outlined,
        SensorKind.light => Icons.wb_sunny_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorEvent>(
      stream: events,
      builder: (context, snapshot) {
        final event = snapshot.data;
        final reading = event?.reading;
        final failure = event?.failure;
        final alert = reading != null && sensor.isOutOfRange(reading.value);
        final tint = failure != null
            ? Colors.red
            : alert
                ? Colors.deepOrange
                : Colors.teal;
        return Card(
          color: tint.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: tint.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(_icon, color: tint),
                  const SizedBox(width: 8),
                  Expanded(child: Text(sensor.kind.title,
                      style: Theme.of(context).textTheme.titleMedium)),
                  if (paused) const Chip(label: Text('Пауза')),
                ]),
                const SizedBox(height: 14),
                if (failure != null) ...[
                  Text(failure, style: const TextStyle(color: Colors.red)),
                  const Text('Інші датчики продовжують працювати.'),
                ] else if (snapshot.hasError) ...[
                  Text('Помилка потоку: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                ] else if (reading == null) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Очікування першого вимірювання…'),
                ] else ...[
                  Text('${reading.value.toStringAsFixed(1)} ${sensor.kind.unit}',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(alert ? '⚠ Поза допустимими межами' : 'У межах норми',
                      style: TextStyle(color: tint, fontWeight: FontWeight.w600)),
                  Text('Оновлено: ${TimeOfDay.fromDateTime(reading.time).format(context)}'),
                ],
                const SizedBox(height: 12),
                Text('Норма: ${sensor.min.toStringAsFixed(0)}–'
                    '${sensor.max.toStringAsFixed(0)} ${sensor.kind.unit}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
