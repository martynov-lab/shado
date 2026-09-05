import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/tts_quota.dart';
import 'package:shado/features/lessons/domain/usecases/synthesize_tts.dart';
import 'package:shado/features/lessons/presentation/controllers/add_lesson_controller.dart';
import 'package:shado/features/lessons/presentation/controllers/lesson_providers.dart';
import 'package:shado/features/lessons/presentation/pages/add_lesson_page.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// A session with the given role, which drives voice-over and privacy.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this.role);

  final UserRole role;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: AuthUser(
      id: 'user-1',
      email: 'author@example.com',
      role: role,
      createdAt: DateTime.utc(2026),
    ),
  );
}

/// A voice-over that always fails with the given error.
class _FailingTts implements SynthesizeTts {
  const _FailingTts(this.error);

  final Object error;

  @override
  Future<AudioUpload> call({required String text, Object? cancel}) async =>
      throw error;
}

/// Lesson creation screen: accent, level and topic pickers.
void main() {
  const topics = [
    Topic(id: 'topic-1', name: 'Education'),
    Topic(id: 'topic-2', name: 'Business'),
  ];

  // Default voice-over balance keeps `ttsQuotaProvider` offline.
  const defaultQuota = TtsQuota(
    provider: 'gemini',
    day: TtsQuotaWindow(used: 3, limit: 14, remaining: 11),
    minute: TtsQuotaWindow(used: 0, limit: 2, remaining: 2),
  );

  Future<ProviderContainer> pumpForm(
    WidgetTester tester, {
    List<Topic> available = topics,
    Object? topicsError,
    Object? ttsError,
    TtsQuota quota = defaultQuota,
    String? text,
    UserRole role = UserRole.owner,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(role)),
        topicsProvider.overrideWith((ref) async {
          if (topicsError != null) throw topicsError;
          return available;
        }),
        ttsQuotaProvider.overrideWith((ref) async => quota),
        if (ttsError != null)
          synthesizeTtsProvider.overrideWithValue(_FailingTts(ttsError)),
      ],
    );
    addTearDown(container.dispose);
    // The text is set before painting; without it the voice-over is locked.
    if (text != null) {
      container.read(addLessonControllerProvider.notifier).setText(text);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: const AddLessonPage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Opens the list and picks the item labeled [label].
  Future<void> choose(
    WidgetTester tester,
    String fieldLabel,
    String label,
  ) async {
    await tester.tap(find.byKey(ValueKey('dropdown-$fieldLabel')));
    await tester.pumpAndSettle();
    // The label shows in the closed field and the open menu; take the last.
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
    // Everything else is filled: the title, some text and uploaded audio.
    const filled = AddLessonFormState(
      title: 'Урок',
      text: 'Раз',
      audioId: 'audio-1',
      durationMs: 10000,
    );

    expect(filled.canSubmit, isFalse);
    // An accent alone is not enough: the server demands a level too.
    expect(filled.copyWith(accent: LessonAccent.us).canSubmit, isFalse);
    expect(filled.copyWith(level: LessonLevel.b1).canSubmit, isFalse);
    expect(
      filled
          .copyWith(accent: LessonAccent.us, level: LessonLevel.b1)
          .canSubmit,
      isTrue,
    );
  });

  // The form renders in full and the create button starts locked.
  testWidgets('на пустой форме кнопка создания заперта', (tester) async {
    await pumpForm(tester);

    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Создать урок'),
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

    // Accent and level do not depend on the directory: they are hardcoded.
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
      overrides: [
        topicsProvider.overrideWith((ref) async => topics),
        ttsQuotaProvider.overrideWith((ref) async => defaultQuota),
      ],
    );
    addTearDown(container.dispose);
    container.read(addLessonControllerProvider.notifier).setTopic('topic-1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: const AddLessonPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(container.read(addLessonControllerProvider).topicId, 'topic-1');

    // The topic was deleted elsewhere and the directory came back without it.
    container.read(addLessonControllerProvider.notifier).dropTopicUnless(const [
      'topic-2',
    ]);
    await tester.pumpAndSettle();

    expect(container.read(addLessonControllerProvider).topicId, isNull);
  });

  // TTS_CLIENT_SPEC §4.1: the daily voice-over balance sits by the button.
  testWidgets('остаток суточных озвучек виден у кнопки', (tester) async {
    await pumpForm(tester);

    expect(find.text('Осталось озвучек сегодня: 11'), findsOneWidget);
  });

  // Voice-over is owner-only: others get neither the button nor the hint.
  testWidgets('у автора не-владельца кнопки озвучки нет', (tester) async {
    await pumpForm(tester, role: UserRole.admin, text: 'Hello there');

    expect(find.widgetWithText(AppButton, 'Озвучить ИИ'), findsNothing);
    expect(find.textContaining('Осталось озвучек сегодня'), findsNothing);
    // File upload stays: the author role does not lose it.
    expect(find.widgetWithText(AppButton, 'Выберите аудио'), findsOneWidget);
  });

  testWidgets('без ограничения (limit 0) остаток не показывается', (
    tester,
  ) async {
    await pumpForm(
      tester,
      quota: const TtsQuota(
        provider: 'gemini',
        day: TtsQuotaWindow(used: 5, limit: 0),
        minute: TtsQuotaWindow(used: 0, limit: 2, remaining: 2),
      ),
    );

    expect(find.textContaining('Осталось озвучек сегодня'), findsNothing);
  });

  // Different voice-over error codes give different snackbar actions.
  testWidgets('озвучка недоступна (503) — предлагает «Повторить»', (
    tester,
  ) async {
    await pumpForm(
      tester,
      ttsError: const ApiException(
        code: ApiErrorCode.ttsUnavailable,
        message: 'сервис не настроен',
        status: 503,
      ),
      text: 'Hello there',
    );

    await tester.tap(find.widgetWithText(AppButton, 'Озвучить ИИ'));
    await tester.pumpAndSettle();

    expect(
      find.text('Озвучка временно недоступна. Попробуйте позже.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Повторить'), findsOneWidget);
  });

  testWidgets('исчерпан лимит (429) — предлагает загрузить файл, без ретрая', (
    tester,
  ) async {
    await pumpForm(
      tester,
      ttsError: const ApiException(
        code: ApiErrorCode.ttsQuotaExceeded,
        message: 'Бесплатный лимит озвучки на этот месяц исчерпан',
        status: 429,
      ),
      text: 'Hello there',
    );

    await tester.tap(find.widgetWithText(AppButton, 'Озвучить ИИ'));
    await tester.pumpAndSettle();

    expect(
      find.text('Бесплатный лимит озвучки на этот месяц исчерпан'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Загрузить файл'), findsOneWidget);
    // A rate limit is not auto-retried, so no retry button here.
    expect(find.widgetWithText(AppButton, 'Повторить'), findsNothing);
  });
}
