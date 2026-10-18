import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:greenhouse_async/models/sensor.dart';
import 'package:greenhouse_async/services/fake_api.dart';
import 'package:greenhouse_async/services/greenhouse_service.dart';
import 'package:greenhouse_async/services/sensor_monitor.dart';

void main() {
  test('контролер віддає показання та зупиняється на паузі', () async {
    final monitor = SensorMonitor(GreenhouseService(api: FakeApi(failureRate: 0)));
    final values = <SensorEvent>[];
    final subscription = monitor.eventsFor(SensorKind.temperature).listen(values.add);
    monitor.start([SensorKind.temperature]);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(values.any((event) => event.reading != null), isTrue);
    monitor.stop();
    expect(monitor.isRunning, isFalse);
    await subscription.cancel();
    await monitor.dispose();
  });

  test('addError не завершує потік після збою датчика', () async {
    final api = FakeApi(failureRate: 1);
    final monitor = SensorMonitor(GreenhouseService(api: api));
    final events = <SensorEvent>[];
    final subscription = monitor.eventsFor(SensorKind.light).listen(events.add);
    monitor.start([SensorKind.light]);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(events.any((event) => event.failure != null), isTrue);
    api.failureRate = 0;
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    expect(events.any((event) => event.reading != null), isTrue);
    monitor.stop();
    await subscription.cancel();
    await monitor.dispose();
  });
}
