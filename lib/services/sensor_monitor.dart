import 'dart:async';

import '../models/sensor.dart';
import 'greenhouse_service.dart';

/// Один broadcast-контролер передає виміри; помилки надходять через addError.
/// Помилки перетворюються у локальну подію тільки для відповідної картки.
class SensorMonitor {
  SensorMonitor(this.service);

  final GreenhouseService service;
  final StreamController<SensorReading> _controller =
      StreamController<SensorReading>.broadcast();
  Timer? _timer;
  final Set<SensorKind> _busy = {};
  List<SensorKind> _activeKinds = [];
  bool _disposed = false;

  bool get isRunning => _timer != null;

  Stream<SensorEvent> eventsFor(SensorKind kind) =>
      _controller.stream.transform(
        StreamTransformer<SensorReading, SensorEvent>.fromHandlers(
          handleData: (reading, sink) {
            if (reading.kind == kind) sink.add(SensorEvent.reading(reading));
          },
          handleError: (error, stackTrace, sink) {
            if (error is SensorFailure && error.kind == kind) {
              sink.add(SensorEvent.failure(error.message));
            }
          },
        ),
      );

  void start(List<SensorKind> kinds) {
    if (_disposed) return;
    stop();
    _activeKinds = List<SensorKind>.of(kinds);
    if (_activeKinds.isEmpty) return;
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _tick());
  }

  void _tick() {
    for (final kind in _activeKinds) {
      if (_busy.contains(kind)) continue;
      _busy.add(kind);
      _read(kind);
    }
  }

  Future<void> _read(SensorKind kind) async {
    try {
      final reading = await service.fetchReading(kind);
      if (!_disposed && isRunning && _activeKinds.contains(kind)) {
        _controller.add(reading);
      }
    } catch (error, stackTrace) {
      if (!_disposed && isRunning && _activeKinds.contains(kind)) {
        _controller.addError(
          SensorFailure(kind, 'Збій датчика: $error'),
          stackTrace,
        );
      }
    } finally {
      _busy.remove(kind);
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _activeKinds = [];
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    stop();
    await _controller.close();
  }
}
