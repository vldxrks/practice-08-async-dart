import 'dart:math';

/// Імітація мережі без HTTP, зі змінною частотою збоїв.
class FakeApi {
  FakeApi({double failureRate = 0.2, Random? random})
      : _failureRate = failureRate,
        _random = random ?? Random() {
    this.failureRate = failureRate;
  }

  final Random _random;
  double _failureRate;

  double get failureRate => _failureRate;
  set failureRate(double value) {
    if (value < 0 || value > 1) {
      throw ArgumentError.value(value, 'failureRate', 'Має бути від 0 до 1');
    }
    _failureRate = value;
  }

  Future<T> request<T>(T Function() respond, {int delayMs = 550}) async {
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    if (_random.nextDouble() < failureRate) {
      throw StateError('Сервер тимчасово недоступний');
    }
    return respond();
  }
}
