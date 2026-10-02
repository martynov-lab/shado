---
name: services-and-di
description: >-
  Dependencies and shared state in Shado: Riverpod providers in lib/di/, domain
  services and repositories, use cases, overrides in tests. Use when adding a
  provider, service, repository or use case.
---

# Services and dependencies

Full rules — [docs/state_management.md](../../../docs/state_management.md).

Riverpod is only the DI container here. Screen state lives in Elementary widget
models (see the `adding-a-screen` skill), state shared by screens lives in
domain services.

## Where things go

```text
lib/di/<feature>_providers.dart                  # Provider<T> for everything below
lib/features/<feature>/
  domain/usecases/<action>.dart                  # a class with a call() method
  domain/repositories/<name>_repository.dart     # abstract interface class
  domain/services/<name>_service.dart            # shared state, plain Dart
  data/repositories/<name>_repository_impl.dart  # network, DB, SharedPreferences
  data/datasources/...
```

## Which one to write

| What is needed | What |
| --- | --- |
| One scenario: load, save, validate | use case |
| Access to the network / DB / storage | repository interface + `_impl` |
| A value several screens read and change | service |

## Service checklist

- [ ] Plain Dart: no Flutter, no Riverpod imports.
- [ ] Holds the current value (a getter) and sends changes to a broadcast
      `Stream`.
- [ ] `load()` reads the repository once and caches the future.
- [ ] Rules (clamping, validation) live in the service or a use case.
- [ ] `dispose()` closes the stream controller.

## Provider checklist

- [ ] Only `Provider<T>` in `lib/di/`, typed as the interface.
- [ ] Dependencies through `ref.watch`.
- [ ] A service is closed with `ref.onDispose(service.dispose)`.
- [ ] Imports in `lib/di/` are absolute (`package:shado/...`).

## Template

```dart
// domain/services/playback_settings_service.dart
class PlaybackSettingsService {
  PlaybackSettingsService(this._repository);

  final PlaybackSettingsRepository _repository;
  final StreamController<PlaybackSettings> _changes =
      StreamController.broadcast();

  PlaybackSettings _settings = const PlaybackSettings();
  Future<PlaybackSettings>? _loading;

  PlaybackSettings get settings => _settings;
  Stream<PlaybackSettings> get changes => _changes.stream;

  Future<PlaybackSettings> load() => _loading ??= _restore();

  Future<void> setDefaultSpeed(double speed) =>
      _update(_settings.copyWith(defaultSpeed: speed));

  void dispose() => _changes.close();

  Future<PlaybackSettings> _restore() async {
    _apply(await _repository.load());
    return _settings;
  }

  Future<void> _update(PlaybackSettings next) async {
    if (next == _settings) return;
    _apply(next);
    await _repository.save(next);
  }

  void _apply(PlaybackSettings settings) {
    _settings = settings;
    _changes.add(settings);
  }
}

// lib/di/settings_providers.dart
final playbackSettingsServiceProvider = Provider<PlaybackSettingsService>((ref) {
  final service = PlaybackSettingsService(
    ref.watch(playbackSettingsRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
```

## Common mistakes

| Mistake | The right way |
| --- | --- |
| `Provider<LessonRepositoryImpl>` | `Provider<LessonRepository>` |
| A `Notifier` for state shared by screens | a service in `domain/services/` |
| `ValueNotifier` in a service | a `Stream`; the screen model makes a `ValueNotifier` |
| `SharedPreferences` in a service | a repository in `data/` |
| A provider declared in a feature folder | `lib/di/<feature>_providers.dart` |
| Overriding the service in a test | override the repository |
| The error text is built in data or domain | the widget model builds the text |
