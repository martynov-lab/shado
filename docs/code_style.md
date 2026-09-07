# Code style

The rules Dart code is written and edited by in this project. Widgets and
screens are in [ui_guidelines.md](ui_guidelines.md), state in
[state_management.md](state_management.md), tests in [testing.md](testing.md).

The base lint set is `package:flutter_lints` (see `analysis_options.yaml`).
Everything below is on top of it.

1. [Language and comments](#language-and-comments)
2. [Imports and exports](#imports-and-exports)
3. [Naming](#naming)
4. [Parameters and constructors](#parameters-and-constructors)
5. [Typing](#typing)
6. [Pattern matching](#pattern-matching)
7. [Collections](#collections)
8. [Data models](#data-models)
9. [Errors](#errors)
10. [Constants and magic numbers](#constants-and-magic-numbers)
11. [Asynchrony](#asynchrony)
12. [Feature structure](#feature-structure)

## Language and comments

Identifiers and comments are in English, interface strings are in Russian. Test
descriptions and test data are in English too — see
[testing.md](testing.md#naming).

**A comment is one line.** It names the functionality: what the class, the
method or the field does. Two lines are the ceiling, and only when the meaning
does not fit into one.

What never appears in comments:

* reasoning and justification ("historically", "otherwise we would have to…");
* a walk through edge cases and the alternatives that were not chosen;
* usage examples and run commands — those belong in `docs/`;
* a retelling of code that already reads fine.

```dart
// bad — a five-line essay
/// Upload timeout: 50 MB over a slow link takes minutes.
///
/// It is this one, not [requestTimeout], that decides the fate of an upload.
/// We still cap it rather than dropping the limit: on a dead connection an
/// uncapped request would never fail and the upload would just hang.
static const Duration audioTimeout = Duration(minutes: 10);

// good — what it is
/// Audio file transfer timeout.
static const Duration audioTimeout = Duration(minutes: 10);

// bad — retelling the code
// Set the player speed
await player.setSpeed(speed);

// good — a non-obvious step named briefly
// Stop rather than pause: the next start begins at the segment start.
if (range != null) await _rewindTo(current, range, play: false);
```

Public classes and non-obvious fields are documented with `///`, in a single
phrase. The obvious ones (`build`, `dispose`, an `isEmpty` getter) are not
commented at all.

## Imports and exports

* **Within one feature** (`lib/features/<feature>/**`) — relative paths:
  `import '../../domain/entities/lesson.dart';`
* **Outside the feature** (`core`, `theme`, `widgets`, another feature) —
  absolute: `import 'package:shado/theme/theme.dart';`
* Barrel files (`lib/widgets/widgets.dart`, `lib/theme/theme.dart`) are
  imported whole, not the individual files behind them.
* In a barrel we export by the full path:
  `export 'package:shado/widgets/app_button.dart';`

The order is `dart:` → `package:` → relative, with a blank line between the
groups. Inside a group it is alphabetical (`dart format` together with the IDE
does that; we do not re-sort by hand).

## Naming

**Files** are `snake_case.dart` and the file name repeats the main class:
`segment_tile.dart` → `SegmentTile`.

**Boolean variables and getters** carry an `is`, `has`, `can` or `should`
prefix: `isPlaying`, `hasAudioFile`, `canSubmit`. Negations are avoided:
`isInitialized`, not `isNotInitialized`.

**Widget callbacks** answer the question "when will it be called" — the `on`
prefix:

```dart
final VoidCallback onPlayPressed;
final ValueChanged<int> onSegmentSelected;
```

**Controller and model methods** answer the question "what will happen" —
without `on`: `togglePlay()`, `clearSelection()`, `reload()`.

**Private handlers inside a widget or controller**, called on an event, take
`on`/`_on`: `_onKeyEvent`, `_onPosition`.

**`fetch` vs `get`**: a method whose result is not used (returning
`void`/`Future<void>`) is `fetch*`; a method returning a value is `get*`.

**Interfaces** are declared as `abstract interface class` and given a functional
name without prefixes: `LessonRepository`, `AudioCache` — not
`ILessonRepository`, not `AbstractCache`. Implementations get a suffix by their
nature: `SqfliteLessonLocalDataSource`, `ApiLessonRemoteDataSource`.

**Aliases instead of `Function`**: `VoidCallback`, `ValueChanged<T>`,
`ValueGetter<T>`, `ValueSetter<T>`.

```dart
// bad
final void Function() onTap;
final void Function(String) onTextChanged;

// good
final VoidCallback onTap;
final ValueChanged<String> onTextChanged;
```

**Local variables** get a meaningful word rather than a single letter: `colors`,
`segment`, `controller`, not `c`, `s`, `ctrl`. And only what is read more than
once goes into a variable; a value used in a single place is read in place,
without an intermediate variable.

```dart
// bad — one letter, extracted for a single use
final c = context.colors;
return AppIcon(AppIcons.check, color: c.primary);

// good — read it in place
return AppIcon(AppIcons.check, color: context.colors.primary);

// good — colors is used in several places, so it gets a name
final colors = context.colors;
return DecoratedBox(
  decoration: BoxDecoration(
    color: colors.surface,
    border: Border.all(color: colors.border),
  ),
  child: child,
);
```

## Parameters and constructors

With more than one parameter they are named and each goes on its own line. The
same holds for `enum` values.

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

The exception is a single required positional parameter that reads fine without
a name: `formatPosition(int ms)`, `SegmentRange.single(index)`.

Widget constructors are always `const` when the fields allow it.

## Typing

The analyzer infers the type — we do not repeat it by hand:

```dart
// bad
final String title = lesson.title;
final List<Segment> segments = <Segment>[];

// good
final title = lesson.title;
final segments = <Segment>[];
```

We do not use `dynamic` — `Object?` instead. The exception is the
`fromJson(Map<String, dynamic> json)` signature that `json_serializable`
requires.

```dart
// good
final payload = <String, Object?>{'id': id, 'version': version};
```

`num` is acceptable in a DTO (the server sends both `int` and `double`), but
what travels into the domain is already an `int` or a `double`:
`(json['duration_ms'] as num?)?.toInt() ?? 0`.

**Dot shorthand** (Dart 3.10+): when the type is obvious from the context we
write the short form.

```dart
// bad
setSpeed(PlaybackSpeed.slow);
const Alignment a = Alignment.center;

// good
setSpeed(.slow);
const Alignment a = .center;
```

Only where readability does not suffer: if the line does not make it clear which
type the member belongs to, we keep the full form.

## Pattern matching

Returning a value calls for a `switch` expression; performing a side effect
calls for a `switch` statement. Over `sealed` types and `enum`s the switch must
be exhaustive, without a `default`: then a new variant breaks the build rather
than the runtime behavior.

```dart
Color foreground(AppColors colors) => switch (this) {
  AppButtonVariant.primary => colors.primaryOn,
  AppButtonVariant.secondary => colors.primary,
  AppButtonVariant.ghost => colors.text2,
};
```

The details are in the `dart-pattern-matching` skill.

## Collections

A new collection built from an existing one is assembled with a `for` inside the
literal, not with `map` + `toList()`:

```dart
// bad
children: segments.map((it) => SegmentTile(segment: it)).toList(),

// good
children: [
  for (final segment in segments) SegmentTile(segment: segment),
],
```

A collection leaving a controller or a model is handed out immutable:
`Set.unmodifiable(_loopedSegments)`, `List.unmodifiable(items)`, `const []`.

Empty constant collections are `const []`, `const {}`, not literals recreated
each time.

## Data models

The project has three layers of models, each in its own directory:

| Layer | Directory | File | Class |
| --- | --- | --- | --- |
| Domain | `domain/entities/` | `lesson.dart` | `Lesson` |
| Cache / storage | `data/models/` | `lesson_model.dart` | `LessonModel` (freezed + json) |
| Network | `data/models/` | `lesson_dto.dart` | `LessonDto` |

* A **DTO** repeats the shape of the server response — every field exactly as it
  arrived. New fields in already cached models are made nullable or given a
  `@Default`, otherwise the old cache cannot be read after an update.
* A **domain entity** holds only what the business logic needs and knows about
  neither JSON nor Flutter. The mapping is a `toEntity()` method on the data
  side.
* Inside `data`, freezed models are declared as
  `@freezed abstract class ... with _$X`, and the server keys through
  `@JsonKey(name: 'snake_case')`.
* For freezed sealed unions we call the named constructors
  (`Result.success(...)`) rather than the generated classes directly.

After editing freezed/json models — `dart run build_runner build --force-jit`.

## Errors

* Error models descend from `Exception` (recoverable ones) — in this project
  that means `Failure` from `core/error/failures.dart` and `ApiException`.
* We catch `Exception` and its descendants. `Error` (`TypeError`,
  `ArgumentError`) is not caught — that is a bug, to be fixed rather than
  muffled.
* We rethrow with `rethrow` so as not to lose the stack.
* Our own exceptions override `toString()` — that is how they will be read in
  the logs.

```dart
class VersionConflictFailure implements Failure {
  const VersionConflictFailure(this.serverVersion);

  final int serverVersion;

  @override
  String toString() => 'VersionConflictFailure(serverVersion: $serverVersion)';
}
```

The message for the user is composed by presentation, not by data: what leaves
data is the error type, not a ready phrase.

## Constants and magic numbers

Numbers and strings that carry meaning live in constants:
`core/constants/app_constants.dart` (`kSlowSpeed`, `kNormalSpeed`), and the
design tokens in `lib/theme/tokens/`.

HTTP codes come from `HttpStatus` in `dart:io`, not from literals:

```dart
if (response.statusCode == HttpStatus.preconditionFailed) { ... }
```

Color literals are allowed **only** in `lib/theme/tokens/app_colors.dart`.
Inside widgets a color comes from `context.colors`.

## Asynchrony

* We do not await what need not be awaited — it goes into `unawaited(...)`
  (analytics, or a `player.play()` that only completes at the end of the track).
* After an `await`, `mounted` is checked before touching `context`.
* We do not swallow errors with an empty `catch {}`: either handle it or
  `rethrow`.

## Feature structure

```text
lib/features/<feature>/
  data/
    datasources/     # the interface plus implementations (Api*, Sqflite*, File*)
    models/          # *_dto.dart (network), *_model.dart (cache, freezed)
    repositories/    # *_repository_impl.dart
  domain/
    entities/        # pure domain models
    repositories/    # interfaces
    usecases/        # one class per scenario, invoked through call()
  presentation/
    controllers/     # Riverpod controllers, state, *_providers.dart
    pages/           # screens
    widgets/         # feature widgets, one per file
```

What is common to the whole app lives in `lib/core/` (config, network, storage,
router, constants, error, utils), and the design system in `lib/theme/` and
`lib/widgets/`.
