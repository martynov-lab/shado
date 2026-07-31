# Стиль кода

Правила, по которым пишется и правится Dart-код в этом проекте. Виджеты и
экраны — в [ui_guidelines.md](ui_guidelines.md), состояние — в
[state_management.md](state_management.md), тесты — в [testing.md](testing.md).

Базовый набор линтов — `package:flutter_lints` (см. `analysis_options.yaml`).
Всё ниже — сверх него.

1. [Язык и комментарии](#язык-и-комментарии)
2. [Импорты и экспорты](#импорты-и-экспорты)
3. [Именование](#именование)
4. [Параметры и конструкторы](#параметры-и-конструкторы)
5. [Типизация](#типизация)
6. [Паттерн-матчинг](#паттерн-матчинг)
7. [Коллекции](#коллекции)
8. [Модели данных](#модели-данных)
9. [Ошибки](#ошибки)
10. [Константы и магические числа](#константы-и-магические-числа)
11. [Асинхронность](#асинхронность)
12. [Структура фичи](#структура-фичи)

## Язык и комментарии

Идентификаторы — по-английски, комментарии и строки интерфейса — по-русски.

Комментарий отвечает на вопрос «почему так», а не «что тут написано».
Дублирующий код комментарий не нужен; неочевидное решение без комментария не
оставляем.

```dart
// bad — пересказ кода
// Устанавливаем скорость плеера
await player.setSpeed(speed);

// good — объясняет решение
// Именно остановка, а не пауза: кусок короткий, и следующий пуск естественнее
// начать с его начала, чем с середины фразы.
if (range != null) await _rewindTo(current, range, play: false);
```

Публичные классы и неочевидные поля документируем через `///`.

## Импорты и экспорты

* **Внутри одной фичи** (`lib/features/<feature>/**`) — относительные пути:
  `import '../../domain/entities/lesson.dart';`
* **За пределы фичи** (`core`, `theme`, `widgets`, другая фича) — абсолютные:
  `import 'package:shado/theme/theme.dart';`
* Файлы-барели (`lib/widgets/widgets.dart`, `lib/theme/theme.dart`)
  импортируем целиком, а не отдельные файлы за ними.
* В барели экспортируем полным путём: `export 'package:shado/widgets/app_button.dart';`

Порядок: `dart:` → `package:` → относительные, между группами пустая строка.
Внутри группы — по алфавиту (это делает `dart format` вместе с IDE, руками не
пересортировываем).

## Именование

**Файлы** — `snake_case.dart`, имя файла повторяет главный класс:
`segment_tile.dart` → `SegmentTile`.

**Логические переменные и геттеры** — с префиксом `is`, `has`, `can`, `should`:
`isPlaying`, `hasAudioFile`, `canSubmit`. Отрицаний избегаем: `isInitialized`,
а не `isNotInitialized`.

**Колбэки виджетов** отвечают на вопрос «когда вызовется» — префикс `on`:

```dart
final VoidCallback onPlayPressed;
final ValueChanged<int> onSegmentSelected;
```

**Методы контроллеров и моделей** отвечают на вопрос «что произойдёт» — без
`on`: `togglePlay()`, `clearSelection()`, `reload()`.

**Приватные обработчики внутри виджета/контроллера**, вызываемые по событию, —
с `on`/`_on`: `_onKeyEvent`, `_onPosition`.

**`fetch` vs `get`**: метод, результат которого не используется (возвращает
`void`/`Future<void>`), — `fetch*`; метод, возвращающий значение, — `get*`.

**Интерфейсы** описываем как `abstract interface class` и даём функциональное
имя без приставок: `LessonRepository`, `AudioCache` — не `ILessonRepository`,
не `AbstractCache`. Реализации получают суффикс по сути:
`SqfliteLessonLocalDataSource`, `ApiLessonRemoteDataSource`.

**Алиасы вместо `Function`**: `VoidCallback`, `ValueChanged<T>`,
`ValueGetter<T>`, `ValueSetter<T>`.

```dart
// bad
final void Function() onTap;
final void Function(String) onTextChanged;

// good
final VoidCallback onTap;
final ValueChanged<String> onTextChanged;
```

## Параметры и конструкторы

Если параметров больше одного — они именованные и каждый с новой строки. То же
для значений `enum`.

```dart
// bad
SegmentTile({super.key, required this.segment, required this.isPlaying});
void moveFocus(int delta, bool extend) {}
enum AppButtonSize { sm, md, lg }

// good
const SegmentTile({
  super.key,
  required this.segment,
  required this.isPlaying,
});

void moveFocus({
  required int delta,
  bool extend = false,
});

enum AppButtonSize {
  sm,
  md,
  lg,
}
```

Исключение — один обязательный позиционный параметр, читаемый без имени:
`formatPosition(int ms)`, `SegmentRange.single(index)`.

Конструкторы виджетов всегда `const`, если позволяют поля.

## Типизация

Тип выводит анализатор — не повторяем его руками:

```dart
// bad
final String title = lesson.title;
final List<Segment> segments = <Segment>[];

// good
final title = lesson.title;
final segments = <Segment>[];
```

`dynamic` не используем — вместо него `Object?`. Исключение — сигнатуры
`fromJson(Map<String, dynamic> json)`, которых требует `json_serializable`.

```dart
// good
final payload = <String, Object?>{'id': id, 'version': version};
```

`num` допустим в DTO (сервер шлёт и `int`, и `double`), но в домен уезжает уже
`int` или `double`: `(json['duration_ms'] as num?)?.toInt() ?? 0`.

**Dot shorthand** (Dart 3.10+): когда тип очевиден из контекста, пишем короткую
форму.

```dart
// bad
setSpeed(PlaybackSpeed.slow);
const Alignment a = Alignment.center;

// good
setSpeed(.slow);
const Alignment a = .center;
```

Только там, где не страдает читаемость: если из строки непонятно, к какому типу
относится член, оставляем полную форму.

## Паттерн-матчинг

Возвращаем значение — `switch`-выражение; делаем побочный эффект —
`switch`-инструкция. По `sealed`-типам и `enum` switch должен быть
исчерпывающим, без `default`: тогда новый вариант сломает сборку, а не поведение
в рантайме.

```dart
Color foreground(AppColors c) => switch (this) {
  AppButtonVariant.primary => c.primaryOn,
  AppButtonVariant.secondary => c.primary,
  AppButtonVariant.ghost => c.text2,
};
```

Подробности — скилл `dart-pattern-matching`.

## Коллекции

Новая коллекция из имеющейся собирается через `for` в литерале, а не `map`
+ `toList()`:

```dart
// bad
children: segments.map((it) => SegmentTile(segment: it)).toList(),

// good
children: [
  for (final segment in segments) SegmentTile(segment: segment),
],
```

Коллекция, уезжающая наружу из контроллера или модели, отдаётся неизменяемой:
`Set.unmodifiable(_loopedSegments)`, `List.unmodifiable(items)`, `const []`.

Пустые константные коллекции — `const []`, `const {}`, а не пересоздаваемые
литералы.

## Модели данных

В проекте три слоя моделей, каждый в своём каталоге:

| Слой | Каталог | Файл | Класс |
| --- | --- | --- | --- |
| Домен | `domain/entities/` | `lesson.dart` | `Lesson` |
| Кеш / хранение | `data/models/` | `lesson_model.dart` | `LessonModel` (freezed + json) |
| Сеть | `data/models/` | `lesson_dto.dart` | `LessonDto` |

* **DTO** повторяет форму ответа сервера — все поля, как они пришли. Новые поля
  в уже кешируемых моделях делаем nullable или с `@Default`, иначе старый кеш
  не прочитается после обновления.
* **Domain entity** содержит только то, что нужно бизнес-логике, и не знает ни
  про JSON, ни про Flutter. Маппинг — методом `toEntity()` на стороне data.
* Внутри `data` freezed-модели описываем через `@freezed abstract class ... with _$X`,
  ключи сервера — через `@JsonKey(name: 'snake_case')`.
* Для sealed-объединений freezed вызываем именованные конструкторы
  (`Result.success(...)`), а не сгенерированные классы напрямую.

После правки freezed/json-моделей — `dart run build_runner build --force-jit`.

## Ошибки

* Модели ошибок наследуются от `Exception` (восстановимые) — в проекте это
  `Failure` из `core/error/failures.dart` и `ApiException`.
* Ловим `Exception` и его наследников. `Error` (`TypeError`, `ArgumentError`) не
  ловим — это баг, его чинят, а не глушат.
* Пробрасываем через `rethrow`, чтобы не терять стек.
* У собственных исключений переопределяем `toString()` — по нему их будут читать
  в логах.

```dart
class VersionConflictFailure implements Failure {
  const VersionConflictFailure(this.serverVersion);

  final int serverVersion;

  @override
  String toString() => 'VersionConflictFailure(serverVersion: $serverVersion)';
}
```

Сообщение для пользователя формирует presentation, а не data: наружу из data
уезжает тип ошибки, а не готовая фраза.

## Константы и магические числа

Числа и строки с смыслом живут в константах: `core/constants/app_constants.dart`
(`kSlowSpeed`, `kNormalSpeed`), токены дизайна — в `lib/theme/tokens/`.

HTTP-коды — `HttpStatus` из `dart:io`, а не литералы:

```dart
if (response.statusCode == HttpStatus.preconditionFailed) { ... }
```

Литералы цветов допустимы **только** в `lib/theme/tokens/app_colors.dart`.
В виджетах цвет берётся из `context.colors`.

## Асинхронность

* Не ждём то, чего ждать не нужно, — заворачиваем в `unawaited(...)`
  (аналитика, `player.play()`, который завершится только в конце трека).
* После `await` перед обращением к `context` проверяем `mounted`.
* Не глотаем ошибки пустым `catch {}`: либо обрабатываем, либо `rethrow`.

## Структура фичи

```text
lib/features/<feature>/
  data/
    datasources/     # интерфейс + реализации (Api*, Sqflite*, File*)
    models/          # *_dto.dart (сеть), *_model.dart (кеш, freezed)
    repositories/    # *_repository_impl.dart
  domain/
    entities/        # чистые модели предметной области
    repositories/    # интерфейсы
    usecases/        # по одному классу на сценарий, вызов через call()
  presentation/
    controllers/     # Riverpod-контроллеры, состояние, *_providers.dart
    pages/           # экраны
    widgets/         # виджеты фичи, по одному в файле
```

Общее для всего приложения — в `lib/core/` (config, network, storage, router,
constants, error, utils), дизайн-система — в `lib/theme/` и `lib/widgets/`.
