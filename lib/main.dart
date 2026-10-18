import 'dart:async';

import 'package:flutter/material.dart';

import 'models/greenhouse_data.dart';
import 'models/sensor.dart';
import 'services/fake_api.dart';
import 'services/greenhouse_service.dart';
import 'services/sensor_monitor.dart';
import 'widgets/sensor_card.dart';

void main() => runApp(const GreenhouseApp());

class GreenhouseApp extends StatelessWidget {
  const GreenhouseApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Розумна теплиця',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          scaffoldBackgroundColor: const Color(0xFFF4F8F5),
        ),
        home: const GreenhouseScreen(),
      );
}

class GreenhouseScreen extends StatefulWidget {
  const GreenhouseScreen({super.key});

  @override
  State<GreenhouseScreen> createState() => _GreenhouseScreenState();
}

class _GreenhouseScreenState extends State<GreenhouseScreen> {
  late final GreenhouseService _service;
  late final SensorMonitor _monitor;
  late final Map<SensorKind, Stream<SensorEvent>> _streams;
  late Future<GreenhouseData> _initialFuture;
  final Map<SensorKind, DateTime> _lastAlert = {};
  final Map<SensorKind, SensorDefinition> _thresholds = {};
  final List<StreamSubscription<SensorEvent>> _subscriptions = [];
  bool _paused = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _service = GreenhouseService(api: FakeApi(failureRate: 0.2));
    _monitor = SensorMonitor(_service);
    _streams = {for (final kind in SensorKind.values) kind: _monitor.eventsFor(kind)};
    for (final kind in SensorKind.values) {
      _subscriptions.add(_streams[kind]!.listen((event) {
        final reading = event.reading;
        final limits = _thresholds[kind];
        if (reading == null || limits == null || !limits.isOutOfRange(reading.value)) return;
        final now = DateTime.now();
        final previous = _lastAlert[kind];
        if (previous != null && now.difference(previous) < const Duration(seconds: 10)) return;
        _lastAlert[kind] = now;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠ ${kind.title}: ${reading.value.toStringAsFixed(1)} ${kind.unit} — поза нормою!'),
          duration: const Duration(seconds: 3),
        ));
      }));
    }
    _initialFuture = _load();
  }

  Future<GreenhouseData> _load() async {
    final generation = ++_generation;
    _monitor.stop();
    final data = await _service.fetchInitialData();
    if (!mounted || generation != _generation) return data;
    _thresholds
      ..clear()
      ..addEntries(data.sensors.map((sensor) => MapEntry(sensor.kind, sensor)));
    _lastAlert.clear();
    if (!_paused) _monitor.start(data.sensors.map((e) => e.kind).toList());
    return data;
  }

  void _reload() {
    setState(() {
      _paused = false;
      _initialFuture = _load();
    });
  }

  void _setPaused(bool value, List<SensorDefinition> sensors) {
    setState(() => _paused = value);
    if (value) {
      _monitor.stop();
    } else {
      _monitor.start(sensors.map((e) => e.kind).toList());
    }
  }

  @override
  void dispose() {
    _generation++;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _monitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('🌿 Розумна теплиця'),
          actions: [
            IconButton(tooltip: 'Оновити', onPressed: _reload,
                icon: const Icon(Icons.refresh)),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Wrap(spacing: 14, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Частота збоїв API:'),
                    DropdownButton<double>(
                      value: _service.api.failureRate,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('0 %')),
                        DropdownMenuItem(value: 0.2, child: Text('20 %')),
                        DropdownMenuItem(value: 0.5, child: Text('50 %')),
                        DropdownMenuItem(value: 1, child: Text('100 %')),
                      ],
                      onChanged: (rate) {
                        if (rate == null) return;
                        _service.api.failureRate = rate;
                        _reload();
                      },
                    ),
                    FilterChip(
                      label: const Text('Порожні дані (демо)'),
                      selected: _service.emptyMode,
                      onSelected: (value) {
                        _service.emptyMode = value;
                        _reload();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: FutureBuilder<GreenhouseData>(
                future: _initialFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: Column(mainAxisSize: MainAxisSize.min,
                      children: [CircularProgressIndicator(), SizedBox(height: 12),
                        Text('Завантаження датчиків, порогів і підсумку…')]));
                  }
                  if (snapshot.hasError) {
                    return _CenteredState(
                      icon: Icons.cloud_off, title: 'Не вдалося завантажити дані',
                      description: '${snapshot.error}',
                      onRetry: _reload,
                    );
                  }
                  final data = snapshot.data!;
                  if (data.sensors.isEmpty) {
                    return _CenteredState(
                      icon: Icons.inbox_outlined, title: 'Немає датчиків',
                      description: 'Сервер повернув порожній список.',
                      onRetry: _reload,
                    );
                  }
                  return ListView(padding: const EdgeInsets.all(16), children: [
                    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Підсумок за добу', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text('Середня температура: ${data.summary.averageTemperature.toStringAsFixed(1)} °C'),
                        Text('Сповіщень сьогодні: ${data.summary.alertsToday}'),
                      ],
                    ))),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                      label: Text(_paused ? 'Продовжити' : 'Пауза'),
                      onPressed: () => _setPaused(!_paused, data.sensors),
                    ),
                    const SizedBox(height: 12),
                    for (final sensor in data.sensors) Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SensorCard(
                        key: ValueKey(sensor.kind),
                        sensor: sensor,
                        events: _streams[sensor.kind]!,
                        paused: _paused,
                      ),
                    ),
                  ]);
                },
              )),
            ]),
          ),
        ),
      );
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.icon, required this.title,
    required this.description, required this.onRetry});

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 56),
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(description, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: onRetry,
        icon: const Icon(Icons.refresh), label: const Text('Повторити')),
    ]),
  ));
}
