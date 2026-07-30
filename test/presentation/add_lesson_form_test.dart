import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/presentation/controllers/add_lesson_controller.dart';
import 'package:shado/features/lessons/presentation/controllers/lesson_providers.dart';
import 'package:shado/features/lessons/presentation/pages/add_lesson_page.dart';

/// Экран создания урока: выбор акцента, уровня и темы.
///
/// Акцент и уровень сервер требует обязательно (§6), поэтому без них кнопка
/// создания недоступна; тема необязательна и приходит справочником.
void main() {
  const topics = [
    Topic(id: 'topic-1', name: 'Education'),
    Topic(id: 'topic-2', name: 'Business'),
  ];

  Future<ProviderContainer> pumpForm(
    WidgetTester tester, {
    List<Topic> available = topics,
    Object? topicsError,
  }) async {
    final container = ProviderContainer(
      overrides: [
        topicsProvider.overrideWith((ref) async {
          if (topicsError != null) throw topicsError;
          return available;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AddLessonPage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Открывает список и выбирает пункт с подписью [label].
  Future<void> choose(
    WidgetTester tester,
    String fieldLabel,
    String label,
  ) async {
    await tester.tap(find.byKey(ValueKey('dropdown-$fieldLabel')));
    await tester.pumpAndSettle();
    // Подпись есть и в закрытом поле, и в открытом меню — берём последнюю.
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('три списка на месте, тема подтягивается с сервера', (
    tester,
  ) async {
    await pumpForm(tester);

    expect(find.text('Акцент'), findsOneWidget);
    expect(find.text('Уровень'), findsOneWidget);
    expect(find.text('Тема'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dropdown-topic')));
    await tester.pumpAndSettle();
    expect(find.text('Education'), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('Без темы'), findsWidgets);
  });

  testWidgets('выбор акцента и уровня попадает в состояние формы', (
    tester,
  ) async {
    final container = await pumpForm(tester);

    await choose(tester, 'accent', 'Британский');
    await choose(tester, 'level', 'C1 — продвинутый');
    await choose(tester, 'topic', 'Education');

    final state = container.read(addLessonControllerProvider);
    expect(state.accent, LessonAccent.uk);
    expect(state.level, LessonLevel.c1);
    expect(state.topicId, 'topic-1');
  });

  test('без акцента и уровня урок не отправляется', () {
    // Всё остальное заполнено: название, кусок текста и загруженное аудио.
    const filled = AddLessonFormState(
      title: 'Урок',
      text: 'Раз',
      audioId: 'audio-1',
      durationMs: 10000,
    );

    expect(filled.canSubmit, isFalse);
    // Одного акцента мало: уровень сервер требует так же.
    expect(filled.copyWith(accent: LessonAccent.us).canSubmit, isFalse);
    expect(filled.copyWith(level: LessonLevel.b1).canSubmit, isFalse);
    expect(
      filled
          .copyWith(accent: LessonAccent.us, level: LessonLevel.b1)
          .canSubmit,
      isTrue,
    );
  });

  // Какие именно поля запирают кнопку, проверяет тест выше на `canSubmit`;
  // здесь — что форма с новыми списками по-прежнему целиком отрисовывается и
  // кнопка приходит запертой.
  testWidgets('на пустой форме кнопка создания заперта', (tester) async {
    await pumpForm(tester);

    // Кнопка внизу формы, а `ListView` строит только видимое.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Создать урок'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('справочник тем не загрузился — форма остаётся рабочей', (
    tester,
  ) async {
    final container = await pumpForm(
      tester,
      topicsError: StateError('нет связи'),
    );

    // Акцент и уровень от справочника не зависят: они зашиты в клиенте.
    await choose(tester, 'accent', 'Американский');
    await choose(tester, 'level', 'A2 — элементарный');

    final state = container.read(addLessonControllerProvider);
    expect(state.accent, LessonAccent.us);
    expect(state.level, LessonLevel.a2);
    expect(state.topicId, isNull);
    expect(
      find.textContaining('Справочник тем не загрузился'),
      findsOneWidget,
    );
  });

  testWidgets('удалённая тема уходит из состояния', (tester) async {
    final container = ProviderContainer(
      overrides: [topicsProvider.overrideWith((ref) async => topics)],
    );
    addTearDown(container.dispose);
    container.read(addLessonControllerProvider.notifier).setTopic('topic-1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AddLessonPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(container.read(addLessonControllerProvider).topicId, 'topic-1');

    // Тему удалили на другом устройстве — справочник вернулся без неё.
    container.read(addLessonControllerProvider.notifier).dropTopicUnless(const [
      'topic-2',
    ]);
    await tester.pumpAndSettle();

    expect(container.read(addLessonControllerProvider).topicId, isNull);
  });
}
