---
name: dart-pattern-matching
description: >-
  Dart 3 pattern matching in Shado: switch expressions, sealed classes,
  handling AsyncState, destructuring records and collections, guard clauses,
  exhaustiveness. Use when refactoring branching and taking structures apart.
---

# Pattern matching

Code style — [docs/code_style.md](../../../docs/code_style.md).

## What to choose

| Task | Tool |
| --- | --- |
| Return a value per variant | a `switch` expression |
| Perform a side effect | a `switch` statement |
| Handle an `AsyncState` | a `switch` over `AsyncReady`/`AsyncFailed`/`AsyncPending` |
| Type-specific behavior | `sealed` + object patterns |
| Several values from a function | a record `(a, b)` and destructuring |
| Ranges and extra conditions | relational patterns and `when` |
| A shared body for several cases | logical "or" `\|\|` |

## Rules

* A switch over a `sealed` type or an `enum` is exhaustive, without `default`:
  a new variant must break the build, not the behavior.
* `when` — only for conditions that cannot be expressed as a pattern.
* An `if` chain of three or more branches on one value becomes a switch.
* Readability beats brevity: patterns nested deeper than two levels are split
  into steps.

## Examples

Screen state:

```dart
body: switch (state) {
  AsyncPending() => const Center(child: CircularProgressIndicator()),
  AsyncFailed(:final error) => LessonLoadError(error: error),
  AsyncReady(:final value) => LessonView(state: value),
},
```

Component variants:

```dart
Color foreground(AppColors c) => switch (this) {
  AppButtonVariant.primary => c.primaryOn,
  AppButtonVariant.secondary => c.primary,
  AppButtonVariant.ghost => c.text2,
};

Color background(AppColors c, {bool hovered = false, bool pressed = false}) =>
    switch (this) {
      AppButtonVariant.primary when pressed => c.primaryPress,
      AppButtonVariant.primary when hovered => c.primaryHover,
      AppButtonVariant.primary => c.primary,
      ...
    };
```

Several values at once:

```dart
final (double height, double padding, TextStyle style) = switch (size) {
  AppButtonSize.sm => (AppSizes.controlSm, AppSpacing.s4, AppText.label),
  AppButtonSize.md => (AppSizes.controlMd, AppSpacing.s5, AppText.label),
  AppButtonSize.lg => (AppSizes.controlLg, AppSpacing.s6, AppText.title),
};
```

Parsing JSON where there is no DTO (DTOs themselves use `json_serializable` and explicit casts):

```dart
if (payload case {'topic': {'id': final String id, 'name': final String name}}) {
  return Topic(id: id, name: name);
}
```

Key handling:

```dart
switch (event.logicalKey) {
  case LogicalKeyboardKey.arrowDown:
    controller.moveFocus(1);
  case LogicalKeyboardKey.space:
    controller.togglePlayFocused();
  default:
    return KeyEventResult.ignored;
}
```

## Verification

The analyzer checks exhaustiveness: after changing a sealed hierarchy or an
enum, run `flutter analyze` (the `resolving-dart-static-analysis-errors`
skill).
