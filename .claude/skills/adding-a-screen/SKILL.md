---
name: adding-a-screen
description: >-
  Добавление нового экрана, виджета или фичи в Shado: файловая структура,
  разбиение на виджеты, дизайн-система, маршрут, подключение контроллера.
  Использовать при создании UI — новый page, widget, раздел фичи.
---

# Новый экран или виджет

Правила целиком — [docs/ui_guidelines.md](../../../docs/ui_guidelines.md),
состояние — [docs/state_management.md](../../../docs/state_management.md).

## Прежде чем писать

- [ ] Прочитать соседний экран той же фичи и повторить его приёмы.
- [ ] Понять, где живут данные: уже есть use case / репозиторий или нужен новый.
- [ ] Проверить, есть ли готовый компонент в `lib/widgets/` и
      `lib/screens/design_gallery.dart` — новый пишем, только если нет.

## Файлы

```text
lib/features/<feature>/presentation/
  pages/<name>_page.dart          # Scaffold, AppBar, подписка на состояние
  widgets/<part>.dart             # каждая часть экрана — свой файл
  controllers/<name>_controller.dart  # состояние + провайдер экрана
```

Жёсткие правила:

- **один виджет — один файл**; приватных `_SomeView` в файле экрана не бывает;
- **никаких `Widget _buildX()`** — вместо метода класс виджета;
- тело экрана (`body`) — отдельный виджет, чтобы его можно было тестировать без
  `Scaffold` и роутера.

## Порядок работы

1. **Состояние.** Нужна асинхронная загрузка или изменяемое состояние — заводим
   контроллер (`AsyncNotifier`/`Notifier`) и провайдер рядом с ним. Экран без
   состояния — обычный `StatelessWidget`.
2. **Экран.** `ConsumerWidget`: `ref.watch` состояния, `ref.read(...notifier)`
   для действий, `switch` по `AsyncValue` для loading/error/data.
3. **Части.** Каждый блок — отдельный виджет, принимающий данные и колбэки
   (`on*`), а не `ref` и не идентификаторы для чтения провайдеров.
4. **Оформление.** Только дизайн-система: `context.colors`, `AppSpacing`,
   `AppRadii`, `AppText`, компоненты `AppButton`, `AppCard`, `AppTextField`
   из `package:shado/widgets/widgets.dart`.
5. **Маршрут.** Добавить `GoRoute` в `lib/core/router/app_router.dart`, путь в
   kebab-case, у экрана — `static const routePath`. Правила доступа — в
   `redirect`, не в виджете.
6. **Доступность.** `tooltip` у иконок, `Semantics` у нестандартных элементов,
   область нажатия ≥ 44 px, горячая клавиша — в подсказке.
7. **Тесты.** Виджет-тест на поведение (см. скилл `writing-flutter-tests`).
8. **Проверка.** `flutter analyze` и `flutter test`.

## Скелет

```dart
// pages/lesson_page.dart
class LessonPage extends ConsumerWidget {
  const LessonPage({super.key, required this.lessonId});

  static const routePath = '/lesson/:lessonId';

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

// widgets/lesson_view.dart
class LessonView extends StatelessWidget {
  const LessonView({
    super.key,
    required this.state,
    required this.onPlayPressed,
  });

  final LessonState state;
  final ValueChanged<int> onPlayPressed;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: state.lesson.segmentCount,
    itemBuilder: (context, index) => SegmentTile(
      segment: state.lesson.segments[index],
      isPlaying: state.isSegmentPlaying(index),
      onPlayPressed: () => onPlayPressed(index),
    ),
  );
}
```

## Частые ошибки

| Ошибка | Как правильно |
| --- | --- |
| `_buildHeader(context)` | класс `LessonHeader` в своём файле |
| `class _SelectionBar` в файле экрана | `widgets/selection_bar.dart`, публичный класс |
| `ref.read` внутри плитки списка | плитка получает данные и `on*`-колбэк |
| `Color(0xFF3B82F6)`, `EdgeInsets.all(16)` | `context.colors.primary`, `AppSpacing.s4` |
| `Center(child: Column(...))` | `Column(mainAxisAlignment: .center, ...)` |
| Корень виджета — `Padding`/`Expanded` | отступ и растяжение задаёт родитель |
| Бизнес-логика в `build` | контроллер и use case |
