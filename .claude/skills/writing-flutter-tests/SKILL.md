---
name: writing-flutter-tests
description: >-
  Writing and editing tests in Shado: unit tests for domain and data, service
  and screen model tests, widget tests, fakes instead of mocks, matchers, running.
  Use when creating or changing any *_test.dart.
---

# Tests

Full rules — [docs/testing.md](../../../docs/testing.md).

Only `flutter_test`. The project has no mocking libraries — fakes are written by
hand as `Fake*` classes implementing the layer interface.

## Where to put it

| What is tested | File |
| --- | --- |
| Entity, use case, service, rules | `test/domain/<name>_test.dart` |
| Repository, mapping, DTO | `test/data/<name>_test.dart` |
| Network, interceptors, storage | `test/core/<name>_test.dart` |
| Screen model, widget, page | `test/presentation/<name>_test.dart` |

## Checklist

- [ ] The test description is in English: "action, result, condition".
- [ ] Tests of a class go in `group('$ClassName', ...)` with interpolation.
- [ ] The second `expect` argument is a matcher (`equals`, `isNull`,
      `hasLength`, `isA<T>()`, `throwsA(...)`), not a bare value.
- [ ] Fakes are `Fake*` classes; ones shared by several files live next to the
      tests.
- [ ] Data is built by a private builder at the end of the file
      (`Lesson _makeLesson(...)`).
- [ ] Resources are closed: `addTearDown(container.dispose)`.
- [ ] The network, database and files are not touched — only fakes.
- [ ] Run: `flutter test <file>`, then the whole `flutter test`.

## Unit test

```dart
void main() {
  group('$Lesson', () {
    test('withSegments rejects a split with a wrong boundary count', () {
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

## Model test

```dart
final container = ProviderContainer(
  overrides: [lessonRepositoryProvider.overrideWithValue(FakeLessonRepository())],
);
addTearDown(container.dispose);
final model = SettingsModel(container);
addTearDown(model.dispose);

await model.changeStudiedLanguage('fr');

expect(fakeRepository.cleared, isTrue);
```

Substitute at the layer boundary (repository, datasource) — the model, service
and use case code stays real. A service is tested without a container, on a
fake repository. The widget model is tested through a widget test of the page.

## Widget test

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

testWidgets('in selection mode a tap on the tile extends the selection', (tester) async {
  final taps = await pumpTile(tester, isSelecting: true);

  await tester.tap(find.text(segment.text));

  expect(taps, equals(['select']));
});
```

A page needs a `ProviderScope` with `overrides`; a widget that takes data and
callbacks does not.

A fixed surface size, when it matters:

```dart
const size = Size(400, 800);
tester.view
  ..devicePixelRatio = 1.0
  ..physicalSize = size;
addTearDown(tester.view.reset);
await tester.binding.setSurfaceSize(size);
```

## Running

```bash
flutter test test/presentation/segment_tile_test.dart
flutter test --name 'selection mode'
flutter test
```

No golden tests. `test/live/` and
`integration_test/` are run by hand and are not part of the regular run.
