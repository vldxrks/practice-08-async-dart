import 'dart:async';
import 'dart:math';

import '../models/greenhouse_data.dart';
import '../models/sensor.dart';
import 'fake_api.dart';

/// Кожен із трьох стартових викликів незалежний, виконується паралельно.
class GreenhouseService {
  GreenhouseService({FakeApi? api, Random? random})
      : api = api ?? FakeApi(),
        _random = random ?? Random();

  final FakeApi api;
  final Random _random;
  bool emptyMode = false;

  Future<List<SensorKind>> fetchSensors() => api.request(
        () => emptyMode ? <SensorKind>[] : SensorKind.values.toList(),
        delayMs: 700,
      );

  Future<Map<SensorKind, (double, double)>> fetchThresholds() => api.request(
        () => <SensorKind, (double, double)>{
          SensorKind.temperature: (18, 30),
          SensorKind.humidity: (40, 75),
          SensorKind.light: (200, 800),
        },
        delayMs: 850,
      );

  Future<DailySummary> fetchSummary() => api.request(
        () => const DailySummary(averageTemperature: 23.7, alertsToday: 2),
        delayMs: 1100,
      );

  Future<GreenhouseData> fetchInitialData() async {
    final responses = await Future.wait<Object>([
      fetchSensors(),
      fetchThresholds(),
      fetchSummary(),
    ]).timeout(const Duration(seconds: 3));

    final kinds = responses[0] as List<SensorKind>;
    final thresholds = responses[1] as Map<SensorKind, (double, double)>;
    final summary = responses[2] as DailySummary;
    return GreenhouseData(
      sensors: [
        for (final kind in kinds)
          SensorDefinition(
            kind: kind,
            min: thresholds[kind]!.$1,
            max: thresholds[kind]!.$2,
          ),
      ],
      summary: summary,
    );
  }

  Future<SensorReading> fetchReading(SensorKind kind) => api.request(() {
        final double value = switch (kind) {
          SensorKind.temperature => 16 + _random.nextDouble() * 18,
          SensorKind.humidity => 30 + _random.nextDouble() * 55,
          SensorKind.light => 120 + _random.nextDouble() * 850,
        };
        return SensorReading(kind: kind, value: value, time: DateTime.now());
      }, delayMs: 200 + _random.nextInt(280));
}
