---
name: dart-pattern-matching
description: >-
  Паттерн-матчинг Dart 3 в Shado: switch-выражения, sealed-классы, разбор
  AsyncValue, деструктуризация записей и коллекций, guard-условия,
  исчерпываемость. Использовать при рефакторинге ветвлений и разборе структур.
---

# Паттерн-матчинг

Стиль кода — [docs/code_style.md](../../../docs/code_style.md).

## Что выбрать

| Задача | Средство |
| --- | --- |
| Вернуть значение по варианту | `switch`-выражение |
| Сделать побочный эффект | `switch`-инструкция |
| Разобрать `AsyncValue` | `switch` по `AsyncData`/`AsyncError`/`AsyncLoading` |
| Тип-специфичное поведение | `sealed` + объектные паттерны |
| Несколько значений из функции | запись `(a, b)` и деструктуризация |
| Диапазоны и доп. условия | реляционные паттерны и `when` |
| Общее тело для нескольких веток | логическое «или» `\|\|` |

## Правила

* По `sealed`-типу и `enum` switch исчерпывающий, без `default`: новый вариант
  должен ломать сборку, а не поведение.
* `when` — только для условий, которые нельзя выразить паттерном.
* В `if`-цепочке из трёх и более веток по одному значению — переходим на switch.
* Читаемость важнее краткости: вложенность паттернов глубже двух уровней
  разбираем на шаги.

## Примеры

Состояние экрана:

```dart
body: switch (state) {
  AsyncLoading() => const Center(child: CircularProgressIndicator()),
  AsyncError(:final error) => LessonLoadError(error: error),
  AsyncData(:final value) => LessonView(state: value),
},
```

Варианты компонента:

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

Несколько значений сразу:

```dart
final (double height, double padding, TextStyle style) = switch (size) {
  AppButtonSize.sm => (AppSizes.controlSm, AppSpacing.s4, AppText.label),
  AppButtonSize.md => (AppSizes.controlMd, AppSpacing.s5, AppText.label),
  AppButtonSize.lg => (AppSizes.controlLg, AppSpacing.s6, AppText.title),
};
```

Разбор JSON там, где нет DTO (в самих DTO — `json_serializable` и явные касты):

```dart
if (payload case {'topic': {'id': final String id, 'name': final String name}}) {
  return Topic(id: id, name: name);
}
```

Обработка клавиш:

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

## Проверка

Исчерпываемость проверяет анализатор: после правки sealed-иерархии или enum'а —
`flutter analyze` (скилл `resolving-dart-static-analysis-errors`).
