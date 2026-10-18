# Практична робота №8 — Робота з асинхронним кодом у Dart

**Дисципліна:** Програмування для мобільних платформ  
**Варіант 1:** Моніторинг розумної теплиці  
**Мета:** `Future`, `Stream`, паралельні запити, тайм-аути, обробка помилок та коректне звільнення ресурсів.

## Функціональність

- Три датчики: температура (18–30 °C), вологість (40–75 %), освітленість (200–800 лк).
- Одне завантаження **списку датчиків, порогів, добового підсумку**: `Future.wait`, загальний індикатор, тайм-аут 3 с.
- Оновлення кожні **1,5 с** за допомогою `Timer.periodic` та `StreamController.broadcast()`.
- Кожен датчик показує вимір або власну помилку; невдалий запит надсилається через `addError`, а потік продовжує роботу.
- Вихід показника за поріг підсвічує картку; `SnackBar` для датчика обмежено одним повідомленням за 10 с.
- «Пауза / Продовжити» фізично вимикає / вмикає таймер джерела, а не приховує віджети.
- Стани: завантаження, помилка + «Повторити», порожньо + «Повторити», дані та живе оновлення.
- Селектор збоїв (0 %, 20 %, 50 %, 100 %) і демо-перемикач порожніх даних для захисту.

## Запуск

Потрібно встановити **Flutter SDK** (версія з Dart >= 3.3), Android Studio або Chrome; налаштувати `flutter doctor`.

```bash
flutter pub get
flutter run -d chrome
# Або: flutter run -d <id-вашого-Android-пристрою>
flutter run -d chrome
flutter test
```

У проєкті є `lib/`, `test/`, базові Flutter Android- та Web-файли. Якщо ваша версія Flutter вимагає оновлення платформних шаблонів або відсутнього Gradle wrapper JAR, **перед запуском** виконайте в корені проєкту:

```bash
flutter create --platforms=android,web --project-name=greenhouse_async .
flutter pub get
```

Це збереже авторський код `lib/` і тести `test/`. Жодних додаткових мережевих пакетів немає — сервіс імітує API локально.

## Де виконані технічні вимоги

| Вимога | Файл, реалізація |
| --- | --- |
| `Future.wait` + `.timeout(3 с)` | `lib/services/greenhouse_service.dart` → `fetchInitialData()` |
| Імітація мережі, конфігуровані збої | `lib/services/fake_api.dart` → `request()` |
| `FutureBuilder`, Future не в `build()` | `lib/main.dart` → `_initialFuture`, `_load()`, `FutureBuilder` |
| Власний `StreamController`, `addError` | `lib/services/sensor_monitor.dart` → `_controller`, `_read()` |
| `StreamBuilder`, незалежні помилки датчиків | `lib/widgets/sensor_card.dart` і `SensorMonitor.eventsFor()` |
| Пауза справді зупиняє джерело | `SensorMonitor.stop()` скасовує `Timer.periodic` |
| `dispose()` | `lib/main.dart` → скасування підписок; `sensor_monitor.dart` → таймер + `close()` |
| `mounted` після `await` | `lib/main.dart` → `_load()` |
| Затримка сповіщень на 10 секунд | `lib/main.dart` → `_lastAlert` |
| Моделі в окремих файлах | `lib/models/*.dart` |

## Скриншоти
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/265eddc1-8c45-4b1b-ad57-6b0b40272ef0" />
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/f7b2df3d-0624-4dbe-b406-576a4809bbd4" />
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/d0b499e3-532e-43e2-a656-36f64798cc33" />
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/b37ecf86-6485-4f72-9a64-aaa726161314" />
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/8783dacb-c7e8-4af1-82d1-9237166c1130" />
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/2db38bf4-72ce-4a2a-9113-a97236f221e2" />






