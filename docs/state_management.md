# State and dependencies (Riverpod)

How providers, controllers and dependency injection are arranged. Widgets are in
[ui_guidelines.md](ui_guidelines.md), the code style in
[code_style.md](code_style.md).

The version is `flutter_riverpod ^3.3`. Code generation (`@riverpod`) is **not
used**: providers are declared by hand. Uniformity wins — a new provider is
written in the same shape as its neighbours.

1. [Layers](#layers)
2. [Providers](#providers)
3. [Controllers](#controllers)
4. [Screen state](#screen-state)
5. [Reading providers](#reading-providers)
6. [Errors and loading](#errors-and-loading)
7. [Resources and lifecycle](#resources-and-lifecycle)
8. [Substitution in tests](#substitution-in-tests)

## Layers

```text
UI (widgets)  →  controller  →  use case  →  repository  →  datasource
                    │              │            │              │
               screen state    scenario   domain, interface  network / DB / files
```

The rules of movement:

* a widget knows about the controller, the controller about use cases, a use
  case about the repository interface, and the repository about the source
  interfaces;
* there are no back references: the repository does not know about the
  controller, and the domain knows about neither Flutter nor dio;
* a layer may be skipped downwards but not upwards: a controller is allowed to
  take the repository directly when there is no scenario — but a new scenario is
  written as a use case.

A **use case** is a class with a single public `call()` method:

```dart
class GetLesson {
  const GetLesson(this._repository);

  final LessonRepository _repository;

  Future<Lesson> call(String id) async { ... }
}
```

## Providers

All the providers of a feature are gathered in one file,
`presentation/controllers/<feature>_providers.dart` — the composition root of
the feature. A controller provider is declared next to the controller itself, in
its own file.

| What | Provider |
| --- | --- |
| A dependency (datasource, repository, use case) | `Provider<T>` |
| A one-off stateless read (a directory, a list) | `FutureProvider` |
| Screen state with an asynchronous load | `AsyncNotifierProvider` |
| State without an asynchronous load | `NotifierProvider` |

```dart
final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepositoryImpl(
    localDataSource: ref.watch(lessonLocalDataSourceProvider),
    remoteDataSource: ref.watch(lessonRemoteDataSourceProvider),
  ),
);

final getLessonProvider = Provider<GetLesson>(
  (ref) => GetLesson(ref.watch(lessonRepositoryProvider)),
);
```

* The provider type is spelled as the interface (`Provider<LessonRepository>`),
  not as the implementation — otherwise a test cannot substitute it.
* Inside a provider, dependencies are taken through `ref.watch` rather than
  created directly.
* `autoDispose` is for everything tied to a screen (screen state, the player, a
  directory that may have gone stale). Without `autoDispose` we leave the global
  things: the session, `ApiClient`, the repositories.
* `family` is for when a provider depends on an identifier
  (`lessonControllerProvider(lessonId)`). The parameter must be comparable: a
  string, a number, or a `const` object with `==`.
* A provider that is declared but read nowhere is not created.

## Controllers

A controller is an `AsyncNotifier`/`Notifier` in
`presentation/controllers/<name>_controller.dart`. It holds the screen state and
the interaction logic; domain logic that belongs elsewhere is not in it — that
moves into a use case.

```dart
class LessonController extends AsyncNotifier<LessonState> {
  LessonController(this.lessonId);

  final String lessonId;

  @override
  Future<LessonState> build() async {
    final lesson = await ref.watch(getLessonProvider)(lessonId);
    return LessonState(lesson: lesson, speed: kNormalSpeed);
  }

  Future<void> togglePlay(int index) async { ... }
}

final lessonControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LessonController, LessonState, String>(LessonController.new);
```

* `build()` only assembles the initial state — no side effects beyond
  subscriptions, which are torn down right away through `ref.onDispose`.
* Public methods are named after the action: `togglePlay`, `setSpeed`,
  `clearSelection`, `reload`. The `on` prefix belongs to event handlers only
  (`_onPlayerState`).
* A method starts by checking that the state is ready:
  `final current = state.value; if (current == null) return;`.
* Whatever must survive a `build()` rebuild (the speed, flags, the selection
  anchor) is kept in controller fields, not only in the state.
* A controller knows nothing about `BuildContext`, `Navigator` or
  `ScaffoldMessenger`. It changes the state; showing dialogs and navigating away
  is the widget's job, reacting to the state (`ref.listen`).

## Screen state

The state is a separate immutable class in the controller file:

* every field is `final` and the constructor is `const`;
* derived values are getters (`isSelectionPlaying`, `selectionDurationMs`)
  rather than duplicating fields;
* `copyWith` resets through explicit flags (`clearSelection: true`), because
  `null` in `copyWith` means "leave unchanged";
* collections handed outwards are immutable (`Set.unmodifiable`).

We do not introduce flags that describe the same thing in different words: when
a screen has more than two or three states, an `enum` or a sealed class with a
`switch` over it is better.

## Reading providers

| Where | How |
| --- | --- |
| In a widget `build` — subscribing to data | `ref.watch(provider)` |
| In a callback (`onPressed`, a key handler) | `ref.read(provider.notifier)` |
| A side effect on a change (a snackbar, navigation) | `ref.listen(provider, ...)` |
| Inside a provider or controller | `ref.watch` for dependencies, `ref.read` for one-off calls |

We do not call `ref.watch` in callbacks, nor `ref.read` in `build` (except for
`.notifier`, which has no state to subscribe to).

Subscribe to the minimum:
`ref.watch(authControllerProvider.select((s) => s.status))` rebuilds the widget
only when the status changes.

Ref is not threaded down the tree — see
[ui_guidelines.md](ui_guidelines.md#data-and-callbacks).

## Errors and loading

* An asynchronous operation whose result the user sees is wrapped in
  `AsyncValue.guard` — the error state lands in `state` rather than in the
  console.
* The error type comes from the domain (`Failure`, `ApiException`); the text for
  the user is assembled by presentation.
* In an `AsyncNotifier` we do not swap `state` for `AsyncLoading` on every
  action: a full-page spinner instead of a pressed button is almost always a
  mistake. For "a request is running" we keep a flag in the state (`isBusy`).

## Resources and lifecycle

* Everything created in a provider that needs closing (a player, a subscription,
  a `ValueNotifier`, a `StreamSubscription`) is torn down through
  `ref.onDispose`.
* A provider that owns a resource is kept apart from the controller when the
  resource outlives a state rebuild (`lessonAudioPlayerProvider`).
* `keepAlive` is enabled deliberately and with a comment saying why.

## Substitution in tests

Providers are substituted through `overrideWith`/`overrideWithValue` — in a
`ProviderScope` for widget tests and in a `ProviderContainer` for unit tests:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      lessonRepositoryProvider.overrideWithValue(FakeLessonRepository()),
    ],
    child: const ShadoApp(),
  ),
);
```

We substitute at a layer boundary (the repository, the datasource), not in the
middle: then the test exercises the real controller code. The details are in
[testing.md](testing.md).
