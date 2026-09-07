# Tests

What we check and how. Test code follows the same rules as the rest —
[code_style.md](code_style.md).

1. [Kinds of tests](#kinds-of-tests)
2. [Where the file goes](#where-the-file-goes)
3. [Naming](#naming)
4. [Fakes instead of mocks](#fakes-instead-of-mocks)
5. [Matchers](#matchers)
6. [Unit tests for domain and data](#unit-tests-for-domain-and-data)
7. [Controller tests](#controller-tests)
8. [Widget tests](#widget-tests)
9. [Live server and integration](#live-server-and-integration)
10. [Running](#running)

## Kinds of tests

| Kind | Where | What it checks |
| --- | --- | --- |
| Unit | `test/domain/`, `test/data/`, `test/core/` | domain rules, mapping, network, repository |
| Controller | `test/presentation/` | screen state transitions on fakes |
| Widget | `test/presentation/` | layout, gestures, that a tap goes where it should |
| Contract | `test/live/live_contract.dart` | a path through the real server (run by hand) |
| Integration | `integration_test/` | platform parts: sound, sqlite, peaks |

New domain logic without a unit test does not count as done. A widget test is
written where there is behavior (a gesture, a mode, a state), not for every
`Text`.

## Where the file goes

`test/` mirrors the layers rather than the `lib/` tree verbatim:
`test/domain/lesson_test.dart`, `test/data/lesson_repository_test.dart`,
`test/presentation/segment_tile_test.dart`. The file name is the class under
test plus `_test.dart`.

The file in `test/live/` deliberately has no `_test` suffix so that a plain
`flutter test` does not pick it up.

## Naming

A test description is "action, result, condition", in English, like the rest of
the code (UI strings stay in Russian — see
[code_style.md](code_style.md)):

```dart
test('outside selection mode there is no checkbox before the text', () { ... });
test('reload clears the selection and the loop', () { ... });
```

Tests of one class are collected in `group('$SegmentRange', ...)` — with
interpolation, so that renaming the class reaches the description. Several
scenarios of one method go into a nested `group('toggled', ...)`.

Values inside a test — lesson and folder titles, names, directory entries — are
in English too. The exception is a string compared against the interface
literally (`find.text('Войти')`): it must match the UI as it is written, so it
stays in Russian.

## Fakes instead of mocks

There are no mock libraries (`mockito`, `mocktail`) in the project and there is
no need to add them without a discussion: the layer boundaries are interfaces,
and a fake is written by hand.

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

* A fake class carries the `Fake` prefix.
* Used in one file — declared in that file; needed by several — moved into a
  separate file next to the tests (like `test/core/fake_http_adapter.dart`).
* Call counters (`syncCalls`) are plain fields, checked with `expect`.
* Test data is assembled by a private builder function at the end of the file:
  `Lesson _makeLesson({int segments = 2})`.

## Matchers

The second argument of `expect` is a matcher, not a bare value:

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

The useful ones: `equals`, `isNull`/`isNotNull`, `isTrue`/`isFalse`,
`hasLength`, `contains`, `isA<T>()`, `throwsA(isA<T>())`, and `closeTo` for
`double`.

## Unit tests for domain and data

The domain is tested without any Flutter scaffolding: build the object, call the
method, check the result. Errors are checked by type, not by message text:

```dart
expect(
  () => lesson.withSegments(texts: const [], boundaries: const [0]),
  throwsA(isA<ValidationFailure>()),
);
```

The repository and the network are checked against fake sources: no real
network, database or files. For dio there is `test/core/fake_http_adapter.dart`.

## Controller tests

The controller is brought up in a `ProviderContainer` with substituted
dependencies:

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

We substitute at a layer boundary (the repository or the datasource) so that the
real code of the controller and the use cases stays under test.

## Widget tests

A widget is brought up with the app theme and, when needed, with a
`ProviderScope`:

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

* The shared `pump*` helper is declared at the top of `main()` — it also
  documents which parameters matter in this file.
* A widget that takes data and callbacks (rather than providers) is tested
  without a `ProviderScope` — one more reason to write them that way.
* We search by meaning: `find.text`, `find.byIcon`, `find.byType`; `find.byKey`
  is for when nothing else tells them apart.
* There are no golden tests in the project: there is no library and nobody
  reviews the references. Should they be needed, the dependency is discussed
  first.

## Live server and integration

`test/live/live_contract.dart` talks to a real server and is run by hand — it is
not part of the ordinary run. `integration_test/` requires a running platform
and checks what cannot be faked: playback, sqlite, peaks. Neither of them should
be the only check of a piece of logic — logic is covered by unit tests.

## Running

```bash
flutter test                                   # the whole ordinary run
flutter test test/presentation/segment_tile_test.dart
flutter test --name 'selection mode'
flutter analyze                                # mandatory before handing over
flutter test integration_test/desktop_pipeline_test.dart -d windows
flutter test test/live/live_contract.dart      # needs a live server
```

A code change is not finished until the tests have been run. If a test fails, we
say so with the output rather than "it mostly works".
