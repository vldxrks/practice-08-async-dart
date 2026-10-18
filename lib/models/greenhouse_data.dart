import 'sensor.dart';

class DailySummary {
  const DailySummary({required this.averageTemperature, required this.alertsToday});
  final double averageTemperature;
  final int alertsToday;
}

class GreenhouseData {
  const GreenhouseData({required this.sensors, required this.summary});
  final List<SensorDefinition> sensors;
  final DailySummary summary;
}
