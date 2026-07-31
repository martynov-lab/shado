---
name: resolving-dart-static-analysis-errors
description: >-
  Исправление ошибок flutter analyze и линтера в Shado: null safety, дженерики,
  переопределения, ошибки после кодогенерации freezed/json_serializable.
  Использовать при разборе диагностики анализатора и после build_runner.
---

# Ошибки анализатора

Конфигурация — `analysis_options.yaml` (`package:flutter_lints` +
исключение сгенерированных файлов). Правила кода —
[docs/code_style.md](../../../docs/code_style.md).

## Порядок

- [ ] `flutter analyze`
- [ ] Ошибки в `*.freezed.dart` / `*.g.dart` — не правим руками:
      `dart run build_runner build --force-jit` (при конфликте — `--delete-conflicting-outputs`)
- [ ] `dart fix --apply` для механических правок
- [ ] Остальное — руками (ниже)
- [ ] Проверить: `flutter analyze` и `flutter test`

## Разбор частых диагностик

**Nullable-получатель.** `?.` или `??`; `!` — только когда «не null»
гарантировано выше по коду и это видно из строки. Поле, которое точно
инициализируют до первого чтения, но не в конструкторе, — `late`.

**Несовпадение типов** (`List<dynamic> can't be assigned`). Ставим явный
аргумент типа литералу: `<Segment>[]`, `<String, Object?>{}`.

**Неисчерпывающий switch.** По `sealed`-типу или `enum` дописываем недостающие
ветки, а не `default` — иначе следующий вариант молча провалится в рантайм.
См. скилл `dart-pattern-matching`.

**Неверное переопределение.** Параметр в наследнике сужать нельзя — либо
расширяем тип, либо помечаем `covariant`, если сужение осознанное.

**`use_build_context_synchronously`.** После `await` проверяем `mounted`
(в `State`) или `context.mounted` — до обращения к `context`, а не `// ignore`.

**Неиспользуемое.** Убираем то, что осталось от собственной правки. Чужой
мёртвый код не трогаем — называем его в ответе.

## Про `// ignore`

Подавление — крайняя мера, только с комментарием, зачем оно здесь. В
`analysis_options.yaml` правило не отключаем ради одного файла.

## Кодогенерация

Правки в `@freezed`- и `@JsonSerializable`-моделях требуют перегенерации:

```bash
dart run build_runner build --force-jit
```

Ошибки вида «`_$LessonModel` не найден» или «part-файл устарел» лечатся ею же, а
не правкой сгенерированного кода.
