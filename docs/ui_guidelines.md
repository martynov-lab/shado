# Виджеты и экраны

Как устроен слой представления. Общий стиль кода — в
[code_style.md](code_style.md), состояние — в
[state_management.md](state_management.md).

1. [Один виджет — один файл](#один-виджет--один-файл)
2. [Никаких методов-билдеров](#никаких-методов-билдеров)
3. [Какой класс виджета выбрать](#какой-класс-виджета-выбрать)
4. [Данные и колбэки](#данные-и-колбэки)
5. [Дизайн-система](#дизайн-система)
6. [Компоновка](#компоновка)
7. [Экран](#экран)
8. [Навигация](#навигация)
9. [Доступность и клавиатура](#доступность-и-клавиатура)
10. [Форматирование данных](#форматирование-данных)

## Один виджет — один файл

Каждый виджет живёт в своём файле, названном по классу. Приватных вложенных
классов-виджетов в файле экрана быть не должно.

```text
# bad
presentation/pages/lesson_page.dart
  class LessonPage
  class _LessonView       ← вложенный виджет в том же файле
  class _SelectionBar     ← и ещё один

# good
presentation/pages/lesson_page.dart      → LessonPage
presentation/widgets/lesson_view.dart    → LessonView
presentation/widgets/selection_bar.dart  → SelectionBar
```

Где лежит файл:

* виджет используется только этой фичей — `features/<feature>/presentation/widgets/`;
* виджет нужен нескольким фичам и не знает о предметной области —
  `lib/widgets/` (дизайн-система) плюс строка в барель `widgets.dart`.

Класс виджета публичный (без `_`), даже если сегодня он используется в одном
месте: файл всё равно отдельный, а приватность здесь ничего не защищает.

## Никаких методов-билдеров

Метод, возвращающий `Widget`, — это виджет, который забыли объявить: он не
получает своего элемента в дереве, перестраивается вместе со всем экраном и не
может быть `const`.

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

Это же касается локальных переменных-виджетов, собираемых в `build` условиями:
если веток больше одной, выносим виджет в класс и передаём в него флаг.

Исключение — только `builder`-колбэки чужих API (`ListView.builder`,
`ValueListenableBuilder`, `showDialog`): там виджет строит фреймворк, и вложенная
функция — часть контракта. Тело такого колбэка должно быть коротким: одна
конструкция виджета, вся логика — снаружи.

## Какой класс виджета выбрать

| Что нужно | Класс |
| --- | --- |
| Только разметка по входным данным | `StatelessWidget` |
| Локальное UI-состояние: фокус, контроллеры, анимации, hover | `StatefulWidget` |
| Чтение провайдеров | `ConsumerWidget` |
| Провайдеры + локальное UI-состояние | `ConsumerStatefulWidget` |

`StatefulWidget` держит только то, что не переживает экран и никому больше не
нужно (`FocusNode`, `TextEditingController`, `ScrollController`, флаги
hover/pressed). Всё, что относится к данным урока, сессии, загрузке, — в
контроллер.

Всё, что создано в `State` и требует освобождения, освобождается в `dispose()`.

## Данные и колбэки

Виджет получает готовые данные и колбэки, а не источник данных. Провайдеры
читаются на экране (или в `ConsumerWidget`, который отвечает за раздел), а не в
глубине дерева.

```dart
// bad — плитка сама лезет в контроллер и знает про lessonId
class SegmentTile extends ConsumerWidget {
  const SegmentTile({super.key, required this.lessonId, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(lessonControllerProvider(lessonId).notifier);
    ...
  }
}

// good — плитка знает только про свой кусок
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

Так виджет тестируется без провайдеров и переиспользуется на другом экране.

Имена колбэков — с `on` (см. [code_style.md](code_style.md#именование)).
Значение колбэка передаём как есть, без обёртки, если ничего не добавляем:
`onPressed: controller.clearSelection`, а не
`onPressed: () => controller.clearSelection()`.

## Дизайн-система

Новый UI собирается из компонентов `lib/widgets/` и токенов `lib/theme/`:

```dart
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

final c = context.colors;

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
      color: c.surface,
      borderRadius: AppRadii.rMd,
      boxShadow: context.shadows.e1,
    ),
    child: ...,
  ),
);
```

Правила:

* цвет — только `context.colors`, никаких `Colors.blue` и `Color(0xFF...)` в
  виджетах;
* отступы и размеры — `AppSpacing`, `AppSizes`, `AppRadii`; «магические» 12, 16,
  24 не пишем;
* типографика — `AppText`;
* длительности анимаций — `AppDurations` через `context.motion(...)`, чтобы
  сработала настройка «убрать анимации»;
* нужного компонента нет — сначала смотрим `lib/screens/design_gallery.dart` и
  соседние `app_*.dart`, потом добавляем новый в `lib/widgets/` по образцу
  `app_button.dart` (варианты enum'ом, состояния считаем сами, токены снаружи).

Часть старых экранов ещё использует `lib/core/theme/app_theme.dart` и голый
Material. Новый код пишем на дизайн-системе; старый переводим отдельной задачей,
а не попутно.

## Компоновка

Расположением и размером виджета управляет родитель.

```dart
// bad
Center(child: Column(children: [...]))
Column(children: [SizedBox(width: double.infinity, child: AppButton(...))])

// good
Column(mainAxisAlignment: MainAxisAlignment.center, children: [...])
Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [AppButton(...)])
```

* Корнем собственного виджета не бывают `Expanded`, `Flexible` и `Padding`:
  отступ и растяжение задаёт тот, кто его вставляет.
* Высоту не фиксируем. Если без фиксации никак (горизонтальный список внутри
  вертикального), высота считается с учётом масштаба текста
  (`MediaQuery.textScalerOf(context)`), а не константой.
* Списки — `ListView.builder`/`SliverList`, а не `Column` внутри
  `SingleChildScrollView`, когда элементов может быть много.

## Экран

Экран — это `pages/<name>_page.dart`. Он отвечает за `Scaffold`, `AppBar`,
подписку на состояние и раздачу данных дочерним виджетам:

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

Тело экрана (то, что попадает в `body`) выносим отдельным виджетом — тогда его
можно проверить тестом, не поднимая `Scaffold` и роутер.

## Навигация

Навигация — `go_router`, маршруты собраны в `lib/core/router/app_router.dart`.

* Путь пишется в kebab-case: `/add-lesson`, `/lesson/:lessonId/edit`.
* Путь и переходы к экрану не разбрасываем строками по виджетам: у экрана
  объявляем `static const routePath` (как у `DesignGalleryScreen`) и ходим по
  нему.
* Правила доступа (сессия, роль) живут в `redirect` роутера, а не в виджетах.
* Возврат результата — типизированно: `context.push<bool>(...)`, и на стороне
  экрана `context.pop(true)`.

## Доступность и клавиатура

* У иконочных кнопок — `tooltip`, у нестандартных элементов — `Semantics` с
  `label`.
* Область нажатия не меньше 44 логических пикселей (`AppTapTarget`).
* Приложение работает на десктопе: если экран отвечает на клавиши, обработка
  живёт в `Focus`/`Shortcuts` на уровне экрана, а сами действия вызывают методы
  контроллера. В подсказках пишем горячую клавишу: «Выбрать все куски (Ctrl+A)».

## Форматирование данных

Приведение к человекочитаемому виду — работа presentation. `DateTime`,
длительности и числа передаём в виджет как есть, форматируем внутри:

```dart
Text(formatPosition(segment.startMs)); // core/utils/duration_format.dart
```

Локализации (`intl`) в проекте нет — строки интерфейса пишутся русскими
литералами прямо в виджете. Повторяющуюся строку выносим в `static const` рядом
с виджетом, а не копируем.
