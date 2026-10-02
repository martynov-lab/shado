---
name: adding-a-screen
description: >-
  Adding a new screen, widget or feature to Shado: the Elementary trio
  (page, widget model, model), splitting into widgets, the design system, the
  route. Use when building UI — a new page, widget or feature section.
---

# A new screen or widget

Full rules — [docs/ui_guidelines.md](../../../docs/ui_guidelines.md),
state — [docs/state_management.md](../../../docs/state_management.md),
widget parameters — [docs/code_style.md](../../../docs/code_style.md#widget-parameters).

## Before writing

- [ ] Read a neighboring screen of the same feature and follow its patterns.
- [ ] Find out where the data lives: a use case, repository or service already
      exists or a new one is needed (see the `services-and-di` skill).
- [ ] Check whether a ready component exists in `lib/widgets/` and
      `lib/screens/design_gallery.dart` — write a new one only if it does not.

## Files

```text
lib/features/<feature>/presentation/
  screens/<name>/<name>_page.dart   # ElementaryWidget: subscribes to the WM, builds widgets
  screens/<name>/<name>_wm.dart     # <Name>WidgetModel + factory: screen state, dialogs, texts
  screens/<name>/<name>_model.dart  # <Name>Model: services, use cases, Riverpod container
  screens/<name>/...                # helpers of this screen only: its state, a form
  widgets/<part>.dart       # every part of the screen is its own file
```

Hard rules:

- **one widget — one file**; no private `_SomeView` classes next to the main
  one, layout variants included;
- **no `Widget _buildX()`** — a widget class instead of a method;
- **widgets never get the widget model** — the page passes values and
  callbacks; views and columns take finished sections as `Widget` parameters;
- the widget model has no separate interface.

## Workflow

1. **Model.** Takes the `ProviderContainer` from the factory, reads services and
   use cases from `lib/di/`. Turns service `Stream`s into `ValueNotifier`s in
   `init()`, cancels them in `dispose()`. Throws errors as they are.
2. **Widget model.** Exposes `ValueListenable`s and public methods. Shows sheets,
   dialogs and snackbars, catches the model's errors and builds the text. Busy
   flags are plain fields.
3. **Page.** `build(wm)` wraps every section in a `ValueListenableBuilder`
   (`ListenableBuilder` for several sources) and passes plain values and `on*`
   callbacks. Async data goes as `AsyncState` and is taken apart with `switch`.
4. **Parts.** Every block is a `StatelessWidget` (or `StatefulWidget` for local
   UI state) that takes data and callbacks.
5. **Adaptivity.** `AppAdaptiveLayout` with a view per platform
   (`_mobile_view` / `_tablet_view`); views take sections as `Widget`
   parameters. Small differences — `context.responsive(...)`.
6. **Styling.** Only the design system: `context.colors`, `AppSpacing`,
   `AppRadii`, `AppText`, components from `package:shado/widgets/widgets.dart`.
7. **Route.** A `GoRoute` in `lib/core/router/app_router.dart`, kebab-case path,
   `static const routePath` on the page. Access rules go in `redirect`.
8. **Accessibility.** `tooltip` on icons, `Semantics` on non-standard elements,
   a tap target ≥ 44 px, the hotkey in the hint.
9. **Tests.** The model in a `ProviderContainer`, the page with a widget test
   (see the `writing-flutter-tests` skill).
10. **Verification.** `flutter analyze` and `flutter test`.

## Skeleton

```dart
// screens/lesson/lesson_model.dart
class LessonModel extends ElementaryModel {
  LessonModel(this._container, this.lessonId);

  final ProviderContainer _container;
  final String lessonId;

  Future<Lesson> loadLesson() => _container.read(getLessonProvider)(lessonId);
}

// screens/lesson/lesson_wm.dart
LessonWidgetModel lessonWidgetModelFactory(BuildContext context) {
  final page = context.widget as LessonPage;
  return LessonWidgetModel(
    LessonModel(ProviderScope.containerOf(context, listen: false), page.lessonId),
  );
}

class LessonWidgetModel extends WidgetModel<LessonPage, LessonModel> {
  LessonWidgetModel(super.model);

  final ValueNotifier<AsyncState<Lesson>> _lesson = ValueNotifier(
    const AsyncPending(),
  );

  ValueListenable<AsyncState<Lesson>> get lesson => _lesson;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    reload();
  }

  Future<void> reload() async {
    _lesson.value = await AsyncState.guard(model.loadLesson);
  }

  @override
  void dispose() {
    _lesson.dispose();
    super.dispose();
  }
}

// screens/lesson/lesson_page.dart
class LessonPage extends ElementaryWidget<LessonWidgetModel> {
  const LessonPage({super.key, required this.lessonId})
    : super(lessonWidgetModelFactory);

  static const routePath = '/lesson/:lessonId';

  final String lessonId;

  @override
  Widget build(LessonWidgetModel wm) {
    return ValueListenableBuilder(
      valueListenable: wm.lesson,
      builder: (_, lesson, _) => switch (lesson) {
        AsyncReady(:final value) => LessonView(lesson: value),
        AsyncFailed() => LessonLoadError(onRetry: wm.reload),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
```

## Common mistakes

| Mistake | The right way |
| --- | --- |
| `LessonSection(wm: wm)` | the page passes values and `on*` callbacks |
| `class _TwoColumns` next to the view | `widgets/<feature>_two_columns.dart`, a public class |
| `_buildHeader(context)` | a `LessonHeader` class in its own file |
| Providers read in a widget or the WM | only the model touches the container |
| `ScaffoldMessenger` in the model | the widget model shows messages |
| `Color(0xFF3B82F6)`, `EdgeInsets.all(16)` | `context.colors.primary`, `AppSpacing.s4` |
| The widget root is `Padding`/`Expanded` | the parent sets padding and stretching |
| Business logic in `build` or the WM | a use case or a service in `domain` |
