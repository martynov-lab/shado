# CLAUDE.md

Instructions for Claude Code on working with this repository. Only the
invariants that always apply live here. Details are in `docs/` (links below).

## Project

Shado is a Flutter app for learning English with the shadowing technique.
What the product does and how the data is organized — see [README.md](README.md).

Stack: Flutter, Dart SDK `^3.10.7` (dot shorthand and patterns are available),
**Riverpod 3** (DI and shared services), **Elementary** (screens), go_router,
freezed + json_serializable, dio, sqflite, just_audio.
Platforms: Android, iOS, Windows, Linux.

## Invariants

1. **Clean architecture, feature-first.** Dependencies point inward:
   `presentation → domain ← data`. The domain knows nothing about Flutter, the
   network or the database.
2. **Riverpod for DI and shared services, Elementary for screens.** A screen
   is Widget + WidgetModel + Model (see
   [state_management.md](docs/state_management.md#screens-elementary)).
   Shared state lives in domain services. No other state managers (bloc,
   GetX) without a separate decision. All providers live in
   `lib/di/`.
3. **One widget — one file.** No private widget classes next to the main
   one, layout variants included (`_TwoColumnSections`): each moves to its own
   file in `widgets/`.
4. **Widgets do not get the WidgetModel.** Only the page's `build(wm)` reads
   the WM: it subscribes with `ValueListenableBuilder` and passes values and
   callbacks down. Layout widgets (views, columns) take finished sections as
   `Widget` parameters.
5. **Widgets are not built by methods.** No `Widget _buildHeader()` — instead
   of a method, a separate widget class embedded in the parent.
6. **Logic is not in the widget.** Business logic lives in `domain` (use case)
   and `data`, screen logic — in the WidgetModel. Only markup stays in
   `build`.
7. **UI is assembled from the design system.** Components — `lib/widgets/`,
   tokens — `lib/theme/` (`context.colors`, `AppSpacing`, `AppRadii`,
   `AppText`). No raw padding numbers or color literals in widgets.
8. **Everything is in English** — comments, identifiers and UI strings.
   A comment is one line (two at most) and names the functionality: what the
   class, method or field does. No reasoning, justifications, comparison of
   alternatives, examples or retelling of the code. The obvious is not
   commented.
9. **Changes are surgical.** Change only what was asked; do not "improve"
   neighboring code. Name unrelated issues you notice in words, do not touch
   them.
10. **Done = verified.** After a code change: `flutter analyze`, the two DCM
   commands below and `flutter test` (or at least the affected test files).
   A failing test is reported plainly, not as "mostly works".
11. **No new dependencies in `pubspec.yaml` without asking.**

## Documents

| Document | About |
| --- | --- |
| [docs/code_style.md](docs/code_style.md) | Naming, imports, typing, models, errors |
| [docs/ui_guidelines.md](docs/ui_guidelines.md) | Widgets, screens, layout, design system, navigation |
| [docs/state_management.md](docs/state_management.md) | Screens (Elementary), services, DI (Riverpod) |
| [docs/testing.md](docs/testing.md) | Kinds of tests, naming, fakes, running |
| [docs/CLIENT_SPEC.md](docs/CLIENT_SPEC.md) | The contract with the server |
| [docs/RUNNING.md](docs/RUNNING.md) | Running on different platforms |

Step-by-step scenarios live in `.claude/skills/`: a new screen
(`adding-a-screen`), services and DI (`services-and-di`), tests
(`writing-flutter-tests`), analyzer errors
(`resolving-dart-static-analysis-errors`), pattern matching
(`dart-pattern-matching`).

## Commands

```bash
flutter pub get
dart run build_runner build --force-jit   # freezed + json_serializable
flutter analyze
dcm analyze --fatal-style --fatal-warnings lib test   # DCM rules from analysis_options.yaml
dcm check-unused-files --fatal-unused lib
flutter test
flutter test test/domain/lesson_test.dart
flutter run --dart-define=SHADO_API_BASE_URL=http://10.0.2.2:8080
```

`.githooks/pre-push` runs the analysis and tests before a push; enable it once
with `git config core.hooksPath .githooks`.

`test/live/live_contract.dart` requires a live server and is deliberately not
picked up by a regular `flutter test`. `integration_test/` requires a running
platform (`-d windows`).

## How to work on a task

1. First read the neighboring code of the same feature and follow its patterns
   — consistency beats personal preference.
2. If a task has several readings, name them and ask instead of choosing
   silently. If the solution is obvious, take it and say which one.
3. The minimal code that solves the task. No "groundwork for the future",
   extra abstractions or handling of impossible cases.
4. State success verifiably: "add validation" → "a test with invalid input
   fails before the change and passes after".
