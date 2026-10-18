import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:greenhouse_async/models/sensor.dart';
import 'package:greenhouse_async/services/fake_api.dart';
import 'package:greenhouse_async/services/greenhouse_service.dart';

void main() {
  test('Future.wait повертає датчики, межі та денний підсумок', () async {
    final service = GreenhouseService(api: FakeApi(failureRate: 0));
    final result = await service.fetchInitialData();
    expect(result.sensors, hasLength(3));
    expect(result.sensors.first.kind, SensorKind.temperature);
    expect(result.sensors.first.min, 18);
    expect(result.summary.averageTemperature, 23.7);
  });

  test('порожній список датчиків підтримується', () async {
    final service = GreenhouseService(api: FakeApi(failureRate: 0));
    service.emptyMode = true;
    expect((await service.fetchInitialData()).sensors, isEmpty);
  });

  test('збій API з частотою 100%', () async {
    final service = GreenhouseService(api: FakeApi(failureRate: 1));
    await expectLater(service.fetchInitialData(), throwsStateError);
  });

  test('вимірювання мають правильний тип датчика', () async {
    final service = GreenhouseService(
      api: FakeApi(failureRate: 0), random: Random(5),
    );
    final reading = await service.fetchReading(SensorKind.humidity);
    expect(reading.kind, SensorKind.humidity);
    expect(reading.value, inInclusiveRange(30, 85));
  });
}
