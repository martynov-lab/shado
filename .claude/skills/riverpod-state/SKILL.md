---
name: riverpod-state
description: >-
  Riverpod в Shado: провайдеры, AsyncNotifier-контроллеры, состояние экрана,
  внедрение зависимостей, autoDispose/family, overrides. Использовать при
  добавлении провайдера, контроллера, use case или репозитория.
---

# Состояние и зависимости

Правила целиком — [docs/state_management.md](../../../docs/state_management.md).

Кодогенерация `@riverpod` не используется — провайдеры пишем руками, как
соседние.

## Куда что класть

```text
lib/features/<feature>/
  domain/usecases/<action>.dart              # класс с методом call()
  domain/repositories/<name>_repository.dart # abstract interface class
  data/repositories/<name>_repository_impl.dart
  presentation/controllers/
    <feature>_providers.dart                 # DI фичи: datasource → repo → use case
    <screen>_controller.dart                 # контроллер + его провайдер + состояние
```

## Выбор провайдера

| Что нужно | Провайдер |
| --- | --- |
| Зависимость (datasource, repository, use case) | `Provider<Интерфейс>` |
| Разовое асинхронное чтение | `FutureProvider` |
| Состояние экрана с загрузкой | `AsyncNotifierProvider` |
| Состояние без загрузки | `NotifierProvider` |

- Тип провайдера — интерфейсом, не реализацией (иначе тест не подменит).
- `autoDispose` — всё, что живёт вместе с экраном; без него — сессия,
  `ApiClient`, репозитории.
- `family` — если состояние зависит от идентификатора.

## Чек-лист нового контроллера

- [ ] Состояние — отдельный неизменяемый класс: `final`-поля, `const`-конструктор,
      геттеры для производных величин, `copyWith` со сбросом через `clear*`-флаги.
- [ ] `build()` собирает начальное состояние; подписки гасятся `ref.onDispose`.
- [ ] Публичные методы названы по действию (`togglePlay`, `reload`), без `on`.
- [ ] В начале метода — `final current = state.value; if (current == null) return;`
- [ ] Ничего про `BuildContext`, `Navigator`, `ScaffoldMessenger`.
- [ ] Асинхронные операции с видимым результатом — через `AsyncValue.guard`.
- [ ] Что переживает пересборку `build()` — полем контроллера.
- [ ] Провайдер объявлен рядом с классом, в конце файла.

## Чтение

| Где | Как |
| --- | --- |
| `build` виджета | `ref.watch(provider)`, при нужде `.select(...)` |
| Колбэк | `ref.read(provider.notifier)` |
| Побочный эффект (снекбар, переход) | `ref.listen(provider, ...)` |
| Внутри провайдера | `ref.watch` для зависимостей |

## Шаблон

```dart
class LessonState {
  const LessonState({required this.lesson, this.isPlaying = false});

  final Lesson lesson;
  final bool isPlaying;

  LessonState copyWith({Lesson? lesson, bool? isPlaying}) => LessonState(
    lesson: lesson ?? this.lesson,
    isPlaying: isPlaying ?? this.isPlaying,
  );
}

class LessonController extends AsyncNotifier<LessonState> {
  LessonController(this.lessonId);

  final String lessonId;

  @override
  Future<LessonState> build() async {
    final lesson = await ref.watch(getLessonProvider)(lessonId);
    return LessonState(lesson: lesson);
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final lesson = await ref.read(getLessonProvider)(lessonId);
      return LessonState(lesson: lesson);
    });
  }
}

final lessonControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LessonController, LessonState, String>(LessonController.new);
```

## Частые ошибки

| Ошибка | Как правильно |
| --- | --- |
| `Provider<LessonRepositoryImpl>` | `Provider<LessonRepository>` |
| `ref.watch` в колбэке кнопки | `ref.read(...notifier)` |
| `ref.read` данных в `build` | `ref.watch` |
| Спиннер на весь экран при каждом действии | флаг `isBusy` в состоянии |
| Логика сети/БД в контроллере | use case → repository → datasource |
| Подписка без `ref.onDispose` | всегда гасим |
| Текст ошибки собирается в data | data отдаёт тип, текст — presentation |
