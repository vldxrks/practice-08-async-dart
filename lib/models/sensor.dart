enum SensorKind { temperature, humidity, light }

extension SensorKindInfo on SensorKind {
  String get id => name;

  String get title => switch (this) {
        SensorKind.temperature => 'Температура',
        SensorKind.humidity => 'Вологість',
        SensorKind.light => 'Освітленість',
      };

  String get unit => switch (this) {
        SensorKind.temperature => '°C',
        SensorKind.humidity => '%',
        SensorKind.light => 'лк',
      };
}

class SensorDefinition {
  const SensorDefinition({required this.kind, required this.min, required this.max});

  final SensorKind kind;
  final double min;
  final double max;

  bool isOutOfRange(double value) => value < min || value > max;
}

class SensorReading {
  const SensorReading({required this.kind, required this.value, required this.time});

  final SensorKind kind;
  final double value;
  final DateTime time;
}

class SensorEvent {
  const SensorEvent.reading(this.reading) : failure = null;
  const SensorEvent.failure(this.failure) : reading = null;

  final SensorReading? reading;
  final String? failure;
}

class SensorFailure implements Exception {
  const SensorFailure(this.kind, this.message);
  final SensorKind kind;
  final String message;

  @override
  String toString() => message;
}
