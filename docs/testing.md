# Тесты

Что и как проверяем. Код тестов подчиняется тем же правилам, что и остальной, —
[code_style.md](code_style.md).

1. [Виды тестов](#виды-тестов)
2. [Где лежит файл](#где-лежит-файл)
3. [Именование](#именование)
4. [Подделки вместо моков](#подделки-вместо-моков)
5. [Матчеры](#матчеры)
6. [Юнит-тесты домена и data](#юнит-тесты-домена-и-data)
7. [Тесты контроллеров](#тесты-контроллеров)
8. [Виджет-тесты](#виджет-тесты)
9. [Живой сервер и интеграция](#живой-сервер-и-интеграция)
10. [Запуск](#запуск)

## Виды тестов

| Вид | Где | Что проверяет |
| --- | --- | --- |
| Юнит | `test/domain/`, `test/data/`, `test/core/` | правила предметной области, маппинг, сеть, репозиторий |
| Контроллер | `test/presentation/` | переходы состояния экрана на подделках |
| Виджет | `test/presentation/` | разметку, жесты, что нажатие уходит куда надо |
| Контракт | `test/live/live_contract.dart` | путь по настоящему серверу (руками) |
| Интеграционный | `integration_test/` | платформенные части: звук, sqlite, пики |

Новая доменная логика без юнит-теста не считается сделанной. Виджет-тест
пишем там, где есть поведение (жест, режим, состояние), а не на каждый `Text`.

## Где лежит файл

`test/` повторяет слои, а не дерево `lib/` дословно: `test/domain/lesson_test.dart`,
`test/data/lesson_repository_test.dart`, `test/presentation/segment_tile_test.dart`.
Имя файла — по тестируемому классу плюс `_test.dart`.

Файл в `test/live/` намеренно без суффикса `_test`, чтобы обычный
`flutter test` его не подхватывал.

## Именование

Описание теста — «действие, результат, условие», по-русски, как в остальном
коде:

```dart
test('вне режима выбора галочки перед текстом нет', () { ... });
test('reload сбрасывает выделение и зацикливание', () { ... });
```

Тесты одного класса собираем в `group('$SegmentRange', ...)` — с интерполяцией,
чтобы переименование класса дошло до описания. Несколько сценариев одного метода
— во вложенную группу `group('toggled', ...)`.

## Подделки вместо моков

Библиотек моков (`mockito`, `mocktail`) в проекте нет и добавлять их без
обсуждения не нужно: границы слоёв — интерфейсы, и подделка пишется руками.

```dart
class FakeLessonRepository implements LessonRepository {
  FakeLessonRepository({this.lessons = const []});

  final List<Lesson> lessons;
  int syncCalls = 0;

  @override
  Future<List<Lesson>> getLessons() async => lessons;
  ...
}
```

* Класс подделки — с префиксом `Fake`.
* Используется в одном файле — объявляем в нём же; нужен нескольким —
  выносим в отдельный файл рядом с тестами (как `test/core/fake_http_adapter.dart`).
* Счётчики вызовов (`syncCalls`) — обычные поля, проверяются `expect`.
* Данные для тестов собираем приватной функцией-билдером в конце файла:
  `Lesson _makeLesson({int segments = 2})`.

## Матчеры

Второй аргумент `expect` — матчер, а не голое значение:

```dart
// bad
expect(taps.length, 1);
expect(state.selection, null);

// good
expect(taps, equals(['focus']));
expect(state.selection, isNull);
expect(segments, hasLength(3));
expect(error, isA<VersionConflictFailure>());
```

Полезные: `equals`, `isNull`/`isNotNull`, `isTrue`/`isFalse`, `hasLength`,
`contains`, `isA<T>()`, `throwsA(isA<T>())`, `closeTo` для `double`.

## Юнит-тесты домена и data

Домен тестируется без Flutter-обвязки: собрали объект, вызвали метод, проверили
результат. Ошибки проверяем типом, а не текстом сообщения:

```dart
expect(
  () => lesson.withSegments(texts: const [], boundaries: const [0]),
  throwsA(isA<ValidationFailure>()),
);
```

Репозиторий и сеть проверяются на подделках источников: без реальной сети, БД и
файлов. Для dio есть `test/core/fake_http_adapter.dart`.

## Тесты контроллеров

Контроллер поднимается в `ProviderContainer` с подменёнными зависимостями:

```dart
final container = ProviderContainer(
  overrides: [
    lessonRepositoryProvider.overrideWithValue(FakeLessonRepository(...)),
  ],
);
addTearDown(container.dispose);

final controller = container.read(lessonControllerProvider('id').notifier);
await container.read(lessonControllerProvider('id').future);

await controller.togglePlay(0);

expect(container.read(lessonControllerProvider('id')).value!.isPlaying, isTrue);
```

Подменяем на границе слоя (репозиторий или datasource), чтобы под тестом
остался настоящий код контроллера и use case'ов.

## Виджет-тесты

Виджет поднимается с темой приложения и, если нужно, с `ProviderScope`:

```dart
Future<List<String>> pumpTile(WidgetTester tester, {required bool isSelecting}) async {
  final taps = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SegmentTile(
          segment: segment,
          isSelecting: isSelecting,
          onSelectPressed: () => taps.add('select'),
          ...
        ),
      ),
    ),
  );
  return taps;
}
```

* Общий `pump*`-хелпер объявляем в начале `main()` — он же документирует, какие
  параметры важны в этом файле.
* Виджет, принимающий данные и колбэки (а не провайдеры), тестируется без
  `ProviderScope` — ещё одна причина писать их так.
* Ищем по смыслу: `find.text`, `find.byIcon`, `find.byType`; `find.byKey` —
  когда иначе не отличить.
* Golden-тестов в проекте нет: библиотеки нет, эталоны никто не сверяет.
  Понадобятся — сначала обсуждаем зависимость.

## Живой сервер и интеграция

`test/live/live_contract.dart` ходит на настоящий сервер и запускается руками —
в обычный прогон он не входит. `integration_test/` требует запущенной
платформы и проверяет то, что нельзя подделать: воспроизведение, sqlite, пики.
Ни то, ни другое не должно быть единственной проверкой логики — логика
покрывается юнит-тестами.

## Запуск

```bash
flutter test                                   # весь обычный прогон
flutter test test/presentation/segment_tile_test.dart
flutter test --name 'режим выбора'
flutter analyze                                # перед сдачей — обязательно
flutter test integration_test/desktop_pipeline_test.dart -d windows
flutter test test/live/live_contract.dart      # нужен живой сервер
```

Правка кода без прогона тестов не заканчивается. Если тест падает — сообщаем об
этом с выводом, а не «в целом работает».
