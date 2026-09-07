# Widgets and screens

How the presentation layer is arranged. The general code style is in
[code_style.md](code_style.md), state in
[state_management.md](state_management.md).

1. [One widget — one file](#one-widget--one-file)
2. [No builder methods](#no-builder-methods)
3. [Which widget class to choose](#which-widget-class-to-choose)
4. [Data and callbacks](#data-and-callbacks)
5. [The design system](#the-design-system)
6. [Layout](#layout)
7. [Adaptive screens](#adaptive-screens)
8. [A screen](#a-screen)
9. [Navigation](#navigation)
10. [Accessibility and the keyboard](#accessibility-and-the-keyboard)
11. [Formatting data](#formatting-data)

## One widget — one file

Every widget lives in its own file, named after the class. There must be no
private nested widget classes inside a screen file.

```text
# bad
presentation/pages/lesson_page.dart
  class LessonPage
  class _LessonView       ← a nested widget in the same file
  class _SelectionBar     ← and one more

# good
presentation/pages/lesson_page.dart      → LessonPage
presentation/widgets/lesson_view.dart    → LessonView
presentation/widgets/selection_bar.dart  → SelectionBar
```

Where the file goes:

* the widget is used by this feature only —
  `features/<feature>/presentation/widgets/`;
* the widget is needed by several features and knows nothing about the domain —
  `lib/widgets/` (the design system) plus a line in the `widgets.dart` barrel.

The widget class is public (no `_`) even when it is used in a single place
today: the file is separate anyway, and privacy protects nothing here.

## No builder methods

A method returning a `Widget` is a widget somebody forgot to declare: it gets no
element of its own in the tree, rebuilds together with the whole screen, and
cannot be `const`.

```dart
// bad
Widget _buildHeader(BuildContext context) => Row(children: [...]);
Widget _buildEmpty() => const Center(child: Text('Пусто'));

@override
Widget build(BuildContext context) => Column(
  children: [_buildHeader(context), _buildEmpty()],
);

// good
@override
Widget build(BuildContext context) => const Column(
  children: [LessonHeader(), EmptyLessonsMessage()],
);
```

The same goes for local widget variables assembled in `build` by conditions:
with more than one branch, the widget moves into a class and takes a flag.

The only exception is the `builder` callbacks of third-party APIs
(`ListView.builder`, `ValueListenableBuilder`, `showDialog`): there the
framework builds the widget and the nested function is part of the contract. The
body of such a callback must be short: one widget construction, with all the
logic outside.

## Which widget class to choose

| What is needed | Class |
| --- | --- |
| Layout from input data only | `StatelessWidget` |
| Local UI state: focus, controllers, animations, hover | `StatefulWidget` |
| Reading providers | `ConsumerWidget` |
| Providers plus local UI state | `ConsumerStatefulWidget` |

A `StatefulWidget` holds only what does not outlive the screen and is of no use
to anyone else (`FocusNode`, `TextEditingController`, `ScrollController`,
hover/pressed flags). Everything about lesson data, the session or loading goes
into the controller.

Everything created in `State` that needs releasing is released in `dispose()`.

## Data and callbacks

A widget receives ready data and callbacks, not a data source. Providers are
read at the screen level (or in the `ConsumerWidget` that owns a section), not
deep in the tree.

```dart
// bad — the tile reaches into the controller and knows lessonId
class SegmentTile extends ConsumerWidget {
  const SegmentTile({super.key, required this.lessonId, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(lessonControllerProvider(lessonId).notifier);
    ...
  }
}

// good — the tile only knows its own slice
class SegmentTile extends StatelessWidget {
  const SegmentTile({
    super.key,
    required this.segment,
    required this.isPlaying,
    required this.onPlayPressed,
  });

  final Segment segment;
  final bool isPlaying;
  final VoidCallback onPlayPressed;
  ...
}
```

That way the widget is tested without providers and reused on another screen.

Callback names take `on` (see [code_style.md](code_style.md#naming)). A callback
value is passed as is, without a wrapper, when nothing is added:
`onPressed: controller.clearSelection`, not
`onPressed: () => controller.clearSelection()`.

## The design system

New UI is assembled from the components in `lib/widgets/` and the tokens in
`lib/theme/`:

```dart
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

AppButton(
  label: 'Создать урок',
  size: AppButtonSize.lg,
  expand: true,
  onPressed: onCreatePressed,
);

Padding(
  padding: const EdgeInsets.all(AppSpacing.s4),
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadii.rMd,
      boxShadow: context.shadows.e1,
    ),
    child: ...,
  ),
);
```

The rules:

* color comes from `context.colors` only — no `Colors.blue` or `Color(0xFF...)`
  inside widgets;
* spacing and sizes come from `AppSpacing`, `AppSizes`, `AppRadii`; we do not
  write magic 12, 16, 24;
* typography comes from `AppText`;
* icons are `AppIcon(AppIcons.play)`: the SVG set from the mockups in
  `assets/app_icons/`. Size and color are taken from `IconTheme`, as with
  `Icon`, or set through tokens (`AppSizes.iconMd`, `context.colors.*`). The
  `AppIconButton`, `AppChip` and `AppBadge` components still take `IconData`
  (Material Icons) — moving them to the set is a task of its own, not something
  done in passing;
* animation durations come from `AppDurations` through `context.motion(...)`, so
  that the "reduce animations" setting takes effect;
* when the component you need does not exist, first look at
  `lib/screens/design_gallery.dart` and the neighbouring `app_*.dart`, then add
  a new one to `lib/widgets/` following `app_button.dart` (variants as an enum,
  states computed internally, tokens from outside).

Some older screens still use `lib/core/theme/app_theme.dart` and bare Material.
New code is written on the design system; the old code is migrated as a separate
task, not in passing.

## Layout

The parent controls the position and the size of a widget.

```dart
// bad
Center(child: Column(children: [...]))
Column(children: [SizedBox(width: double.infinity, child: AppButton(...))])

// good
Column(mainAxisAlignment: MainAxisAlignment.center, children: [...])
Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [AppButton(...)])
```

* `Expanded`, `Flexible` and `Padding` are never the root of a widget of your
  own: padding and stretching are set by whoever inserts it.
* We do not fix the height. When there is no way around it (a horizontal list
  inside a vertical one), the height is computed with the text scale in mind
  (`MediaQuery.textScalerOf(context)`), not as a constant.
* Lists are `ListView.builder`/`SliverList`, not a `Column` inside a
  `SingleChildScrollView`, when there may be many items.

## Adaptive screens

The app runs on phones, tablets and desktops. `AppAdaptiveLayout` picks the
layout by window width — the breakpoints are set in `AppBreakpoints`
(`tablet = 600`, `desktop = 1024`):

```dart
AppAdaptiveLayout(
  mobile: (context) => LessonMobileView(state: state),
  tablet: (context) => LessonTabletView(state: state),
  desktop: (context) => LessonDesktopView(state: state),
);
```

* Only `mobile` is required — it is the base layout. `tablet` and `desktop` are
  optional and fall back to the nearest smaller one (desktop → tablet → phone).
  A screen that gets by with a single wide layout declares it in `tablet` and
  leaves `desktop` empty.
* Each layout is its own widget in its own file (`<screen>_mobile_view.dart`,
  `_tablet_view.dart`, `_desktop_view.dart`), like any other widget (see
  [One widget — one file](#one-widget--one-file)). `AppAdaptiveLayout` builds
  only the chosen variant, so the neighbouring layouts are not built in vain.
* Layouts differ in **composition** (columns, panels, spacing), not in data and
  logic: the state and the callbacks are the same and are handed down by the
  screen above `AppAdaptiveLayout`. `AuthView` with its `AuthDesktopLayout /
  AuthTabletLayout / AuthMobileLayout` is the model to follow.
* A small difference (padding, font size, the number of columns) without a
  separate widget is taken through
  `context.responsive(mobile: ..., tablet: ..., desktop: ...)` or the
  `context.isMobile / isTablet / isDesktop` flags.
* Content on the desktop is not stretched to the full width — it is capped by
  `AppBreakpoints.maxContent`, otherwise the lines of text become unreadably
  long.

## A screen

A screen is `pages/<name>_page.dart`. It is responsible for the `Scaffold`, the
`AppBar`, subscribing to the state and handing data down to the child widgets:

```dart
class LessonPage extends ConsumerWidget {
  const LessonPage({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonControllerProvider(lessonId));
    final controller = ref.read(lessonControllerProvider(lessonId).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(state.value?.lesson.title ?? 'Урок')),
      body: switch (state) {
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncError(:final error) => LessonLoadError(error: error),
        AsyncData(:final value) => LessonView(
          state: value,
          onPlayPressed: controller.togglePlay,
        ),
      },
    );
  }
}
```

The body of the screen (what goes into `body`) is extracted as its own widget —
then it can be checked by a test without bringing up a `Scaffold` and the
router.

## Navigation

Navigation is `go_router`, with the routes gathered in
`lib/core/router/app_router.dart`.

* A path is written in kebab-case: `/add-lesson`, `/lesson/:lessonId/edit`.
* The path and the transitions to a screen are not scattered as strings across
  widgets: the screen declares a `static const routePath` (as
  `DesignGalleryScreen` does) and we navigate by it.
* Access rules (the session, the role) live in the router `redirect`, not in
  widgets.
* Returning a result is typed: `context.push<bool>(...)`, and on the screen side
  `context.pop(true)`.

## Accessibility and the keyboard

* Icon buttons get a `tooltip`, non-standard elements get `Semantics` with a
  `label`.
* The tap target is no smaller than 44 logical pixels (`AppTapTarget`).
* The app runs on the desktop: when a screen responds to keys, the handling
  lives in a `Focus`/`Shortcuts` at the screen level and the actions themselves
  call controller methods. Hints spell the hotkey out: «Выбрать все куски
  (Ctrl+A)».

## Formatting data

Turning values into a human-readable form is presentation work. `DateTime`,
durations and numbers are passed into the widget as they are and formatted
inside:

```dart
Text(formatPosition(segment.startMs)); // core/utils/duration_format.dart
```

There is no localization (`intl`) in the project — interface strings are written
as Russian literals right inside the widget. A repeated string is extracted into
a `static const` next to the widget rather than copied.
