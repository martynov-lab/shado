# Состояние и зависимости (Riverpod)

Как устроены провайдеры, контроллеры и внедрение зависимостей. Виджеты — в
[ui_guidelines.md](ui_guidelines.md), стиль кода — в
[code_style.md](code_style.md).

Версия — `flutter_riverpod ^3.3`. Кодогенерация (`@riverpod`) **не
используется**: провайдеры объявляются руками. Единообразие важнее — новый
провайдер пишем в том же виде, что соседние.

1. [Слои](#слои)
2. [Провайдеры](#провайдеры)
3. [Контроллеры](#контроллеры)
4. [Состояние экрана](#состояние-экрана)
5. [Чтение провайдеров](#чтение-провайдеров)
6. [Ошибки и загрузка](#ошибки-и-загрузка)
7. [Ресурсы и жизненный цикл](#ресурсы-и-жизненный-цикл)
8. [Подмена в тестах](#подмена-в-тестах)

## Слои

```text
UI (виджеты)  →  контроллер  →  use case  →  repository  →  datasource
                    │              │            │              │
              состояние экрана  сценарий    домен, интерфейс  сеть / БД / файлы
```

Правила движения:

* виджет знает про контроллер, контроллер — про use case'ы, use case — про
  интерфейс репозитория, репозиторий — про интерфейсы источников;
* обратных ссылок нет: репозиторий не знает про контроллер, домен не знает про
  Flutter и dio;
* пропускать слой можно вниз, но не вверх: контроллеру не запрещено взять
  репозиторий напрямую, если сценария нет, — но новый сценарий оформляется
  use case'ом.

**Use case** — класс с одним публичным методом `call()`:

```dart
class GetLesson {
  const GetLesson(this._repository);

  final LessonRepository _repository;

  Future<Lesson> call(String id) async { ... }
}
```

## Провайдеры

Все провайдеры фичи собраны в одном файле
`presentation/controllers/<feature>_providers.dart` — это composition root
фичи. Провайдер контроллера объявляется рядом с самим контроллером, в его файле.

| Что | Провайдер |
| --- | --- |
| Зависимость (datasource, repository, use case) | `Provider<T>` |
| Разовое чтение без состояния (справочник, список) | `FutureProvider` |
| Состояние экрана с асинхронной загрузкой | `AsyncNotifierProvider` |
| Состояние без асинхронной загрузки | `NotifierProvider` |

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

* Тип провайдера указываем интерфейсом (`Provider<LessonRepository>`), а не
  реализацией — иначе тест не подменит.
* Внутри провайдера зависимости берутся через `ref.watch`, а не создаются
  напрямую.
* `autoDispose` — для всего, что привязано к экрану (состояние экрана, плеер,
  справочник, который мог устареть). Без `autoDispose` остаются глобальные
  вещи: сессия, `ApiClient`, репозитории.
* `family` — когда провайдер зависит от идентификатора
  (`lessonControllerProvider(lessonId)`). Параметр должен быть сравнимым:
  строка, число, `const`-объект с `==`.
* Провайдер, объявленный, но нигде не читаемый, не создаём.

## Контроллеры

Контроллер — это `AsyncNotifier`/`Notifier` в
`presentation/controllers/<name>_controller.dart`. Он держит состояние экрана и
логику взаимодействия; чужой предметной логики в нём нет — она уезжает в use
case.

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

* `build()` только собирает начальное состояние — никаких побочных эффектов
  сверх подписок, которые тут же гасятся через `ref.onDispose`.
* Публичные методы называются по действию: `togglePlay`, `setSpeed`,
  `clearSelection`, `reload`. Префикс `on` — только у обработчиков событий
  (`_onPlayerState`).
* Метод начинается с проверки, что состояние готово:
  `final current = state.value; if (current == null) return;`.
* То, что должно пережить пересборку `build()` (скорость, флаги, якорь
  выделения), хранится полями контроллера, а не только в состоянии.
* Контроллер не знает про `BuildContext`, `Navigator`, `ScaffoldMessenger`. Он
  меняет состояние; показывает диалоги и уходит на другой экран — виджет,
  реагируя на состояние (`ref.listen`).

## Состояние экрана

Состояние — отдельный неизменяемый класс в файле контроллера:

* все поля `final`, конструктор `const`;
* производные величины — геттеры (`isSelectionPlaying`, `selectionDurationMs`),
  а не дублирующие поля;
* `copyWith` со сбросом через отдельные флаги (`clearSelection: true`), потому
  что `null` в `copyWith` значит «не менять»;
* коллекции наружу — неизменяемые (`Set.unmodifiable`).

Флаги, описывающие одно и то же разными словами, не заводим: если состояний
экрана больше двух-трёх, лучше `enum` или sealed-класс и `switch` по нему.

## Чтение провайдеров

| Где | Как |
| --- | --- |
| В `build` виджета — подписка на данные | `ref.watch(provider)` |
| В колбэке (`onPressed`, обработчик клавиши) | `ref.read(provider.notifier)` |
| Побочный эффект на изменение (снекбар, переход) | `ref.listen(provider, ...)` |
| Внутри провайдера/контроллера | `ref.watch` для зависимостей, `ref.read` для разовых вызовов |

`ref.watch` в колбэках не вызываем, `ref.read` в `build` — тоже (кроме
`.notifier`, у которого нет состояния для подписки).

Подписываемся на минимум: `ref.watch(authControllerProvider.select((s) => s.status))`
перестроит виджет только на смене статуса.

Ref в глубину дерева не прокидываем — см.
[ui_guidelines.md](ui_guidelines.md#данные-и-колбэки).

## Ошибки и загрузка

* Асинхронную операцию, результат которой видит пользователь, оборачиваем в
  `AsyncValue.guard` — состояние ошибки попадёт в `state`, а не в консоль.
* Тип ошибки приезжает из домена (`Failure`, `ApiException`); текст для
  пользователя собирает presentation.
* В `AsyncNotifier` не подменяем `state` на `AsyncLoading` при каждом действии:
  спиннер на всю страницу вместо нажатой кнопки — почти всегда ошибка. Для
  «идёт запрос» держим в состоянии флаг (`isBusy`).

## Ресурсы и жизненный цикл

* Всё, что создано в провайдере и требует закрытия (плеер, подписка,
  `ValueNotifier`, `StreamSubscription`), гасится через `ref.onDispose`.
* Провайдер, владеющий ресурсом, отделяем от контроллера, если ресурс переживает
  перестройку состояния (`lessonAudioPlayerProvider`).
* `keepAlive` включаем осознанно и с комментарием, зачем.

## Подмена в тестах

Провайдеры подменяются через `overrideWith`/`overrideWithValue` — в
`ProviderScope` для виджет-тестов и в `ProviderContainer` для юнит-тестов:

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

Подменяем на границе слоя (репозиторий, datasource), а не на середине: тогда
тест проверяет реальный код контроллера. Подробности — в
[testing.md](testing.md).
