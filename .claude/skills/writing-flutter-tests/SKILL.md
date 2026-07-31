---
name: writing-flutter-tests
description: >-
  Написание и правка тестов в Shado: юнит-тесты домена и data, тесты
  Riverpod-контроллеров, виджет-тесты, подделки вместо моков, матчеры, запуск.
  Использовать при создании или изменении любого *_test.dart.
---

# Тесты

Правила целиком — [docs/testing.md](../../../docs/testing.md).

Только `flutter_test`. Библиотек моков в проекте нет — подделки пишем руками
классами `Fake*`, реализующими интерфейс слоя.

## Куда положить

| Что тестируем | Файл |
| --- | --- |
| Сущность, use case, правила | `test/domain/<name>_test.dart` |
| Репозиторий, маппинг, DTO | `test/data/<name>_test.dart` |
| Сеть, интерцепторы, хранилище | `test/core/<name>_test.dart` |
| Контроллер, виджет, экран | `test/presentation/<name>_test.dart` |

## Чек-лист

- [ ] Описание теста по-русски: «действие, результат, условие».
- [ ] Тесты класса — в `group('$ClassName', ...)` с интерполяцией.
- [ ] Второй аргумент `expect` — матчер (`equals`, `isNull`, `hasLength`,
      `isA<T>()`, `throwsA(...)`), а не голое значение.
- [ ] Подделки — классы `Fake*`; общие для нескольких файлов выносим рядом с
      тестами.
- [ ] Данные собирает приватный билдер в конце файла (`Lesson _makeLesson(...)`).
- [ ] Ресурсы закрываются: `addTearDown(container.dispose)`.
- [ ] Сеть, БД и файлы не трогаются — только подделки.
- [ ] Прогнать: `flutter test <файл>`, затем `flutter test` целиком.

## Юнит-тест

```dart
void main() {
  group('$Lesson', () {
    test('withSegments отвергает разбивку с неверным числом границ', () {
      expect(
        () => _makeLesson().withSegments(
          texts: const ['a', 'b'],
          boundaries: const [0, 100],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}

Lesson _makeLesson({int durationMs = 1000}) => Lesson.withEvenBoundaries(...);
```

## Тест контроллера

```dart
final container = ProviderContainer(
  overrides: [lessonRepositoryProvider.overrideWithValue(FakeLessonRepository())],
);
addTearDown(container.dispose);

await container.read(lessonControllerProvider('id').future);
await container.read(lessonControllerProvider('id').notifier).togglePlay(0);

expect(container.read(lessonControllerProvider('id')).value!.isPlaying, isTrue);
```

Подменяем на границе слоя (репозиторий, datasource) — код контроллера и use
case'ов остаётся настоящим.

## Виджет-тест

```dart
Future<List<String>> pumpTile(WidgetTester tester, {required bool isSelecting}) async {
  final taps = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SegmentTile(..., onSelectPressed: () => taps.add('select'))),
    ),
  );
  return taps;
}

testWidgets('в режиме выбора тап по плитке набирает выделение', (tester) async {
  final taps = await pumpTile(tester, isSelecting: true);

  await tester.tap(find.text(segment.text));

  expect(taps, equals(['select']));
});
```

Виджету с провайдерами нужен `ProviderScope` с `overrides`; виджету, который
принимает данные и колбэки, — не нужен.

Жёсткий размер поверхности, если он важен:

```dart
const size = Size(400, 800);
tester.view
  ..devicePixelRatio = 1.0
  ..physicalSize = size;
addTearDown(tester.view.reset);
await tester.binding.setSurfaceSize(size);
```

## Запуск

```bash
flutter test test/presentation/segment_tile_test.dart
flutter test --name 'режим выбора'
flutter test
```

Golden-тесты не пишем (библиотеки нет). `test/live/` и `integration_test/`
запускаются руками и в обычный прогон не входят.
