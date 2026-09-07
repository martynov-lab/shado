import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/tts_quota.dart';
import 'package:shado/features/languages/domain/entities/language.dart';
import 'package:shado/features/languages/presentation/controllers/language_providers.dart';
import 'package:shado/features/lessons/domain/usecases/synthesize_tts.dart';
import 'package:shado/features/lessons/presentation/controllers/add_lesson_controller.dart';
import 'package:shado/features/lessons/presentation/controllers/lesson_providers.dart';
import 'package:shado/features/lessons/presentation/pages/add_lesson_page.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// A session with the given role, which drives voice-over and privacy.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this.role, this.languageCode);

  final UserRole role;
  final String languageCode;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: AuthUser(
      id: 'user-1',
      email: 'author@example.com',
      role: role,
      createdAt: DateTime.utc(2026),
      studiedLanguage: languageCode,
    ),
  );
}

/// A voice-over that always fails with the given error.
class _FailingTts implements SynthesizeTts {
  const _FailingTts(this.error);

  final Object error;

  @override
  Future<AudioUpload> call({
    required String text,
    String? voice,
    String? accent,
    Object? cancel,
  }) async => throw error;
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

  // English with three accents; the directory drives the accent field.
  const english = Language(
    code: 'en',
    name: 'English',
    accents: [
      Accent(code: 'US', name: 'American', isDefault: true),
      Accent(code: 'UK', name: 'British'),
      Accent(code: 'AU', name: 'Australian'),
    ],
  );
  const french = Language(code: 'fr', name: 'French');

  Future<ProviderContainer> pumpForm(
    WidgetTester tester, {
    List<Topic> available = topics,
    Object? topicsError,
    Object? ttsError,
    TtsQuota quota = defaultQuota,
    String? text,
    UserRole role = UserRole.owner,
    Language language = english,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuthController(role, language.code),
        ),
        languagesProvider.overrideWith((ref) async => [language]),
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

  /// Starts the voice-over; the voice comes from settings, so no sheet opens.
  Future<void> startSynthesis(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'Озвучить ИИ'));
    await tester.pumpAndSettle();
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

  testWidgets('the three pickers are in place and the topic comes from the server', (
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

  testWidgets('the chosen accent and level land in the form state', (
    tester,
  ) async {
    final container = await pumpForm(tester);

    await choose(tester, 'accent', 'British');
    await choose(tester, 'level', 'C1 — продвинутый');
    await choose(tester, 'topic', 'Education');

    final state = container.read(addLessonControllerProvider);
    expect(state.accent, 'UK');
    expect(state.level, LessonLevel.c1);
    expect(state.topicId, 'topic-1');
  });

  test('without an accent and a level the lesson is not submitted', () {
    // Everything else is filled: the title, some text and uploaded audio.
    const filled = AddLessonFormState(
      title: 'Lesson',
      text: 'One',
      audioId: 'audio-1',
      durationMs: 10000,
    );

    expect(filled.isReady(needsAccent: true), isFalse);
    // An accent alone is not enough: the server demands a level too.
    expect(filled.copyWith(accent: 'US').isReady(needsAccent: true), isFalse);
    expect(
      filled.copyWith(level: LessonLevel.b1).isReady(needsAccent: true),
      isFalse,
    );
    expect(
      filled
          .copyWith(accent: 'US', level: LessonLevel.b1)
          .isReady(needsAccent: true),
      isTrue,
    );
  });

  test('a language without accents does not require an accent', () {
    const filled = AddLessonFormState(
      title: 'Lesson',
      text: 'One',
      audioId: 'audio-1',
      durationMs: 10000,
      level: LessonLevel.b1,
    );

    expect(filled.isReady(needsAccent: false), isTrue);
  });

  testWidgets('a language without accents has no accent field', (tester) async {
    await pumpForm(tester, language: french);

    expect(find.text('Акцент'), findsNothing);
    expect(find.text('Уровень'), findsOneWidget);
  });

  testWidgets('English has the Australian accent in the list', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.byKey(const ValueKey('dropdown-accent')));
    await tester.pumpAndSettle();

    expect(find.text('American'), findsWidgets);
    expect(find.text('British'), findsOneWidget);
    expect(find.text('Australian'), findsOneWidget);
  });

  // The form renders in full and the create button starts locked.
  testWidgets('on an empty form the create button is locked', (tester) async {
    await pumpForm(tester);

    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Создать урок'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the topic directory failed to load and the form still works', (
    tester,
  ) async {
    final container = await pumpForm(
      tester,
      topicsError: StateError('no connection'),
    );

    // Accent and level do not depend on the directory: they are hardcoded.
    await choose(tester, 'accent', 'American');
    await choose(tester, 'level', 'A2 — элементарный');

    final state = container.read(addLessonControllerProvider);
    expect(state.accent, 'US');
    expect(state.level, LessonLevel.a2);
    expect(state.topicId, isNull);
    expect(
      find.textContaining('Справочник тем не загрузился'),
      findsOneWidget,
    );
  });

  testWidgets('a deleted topic leaves the state', (tester) async {
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
  testWidgets('the daily voice-over balance shows next to the button', (tester) async {
    await pumpForm(tester);

    expect(find.text('Осталось озвучек сегодня: 11'), findsOneWidget);
  });

  // Voice-over is owner-only: others get neither the button nor the hint.
  testWidgets('an author who is not the owner gets no voice-over button', (tester) async {
    await pumpForm(tester, role: UserRole.admin, text: 'Hello there');

    expect(find.widgetWithText(AppButton, 'Озвучить ИИ'), findsNothing);
    expect(find.textContaining('Осталось озвучек сегодня'), findsNothing);
    // File upload stays: the author role does not lose it.
    expect(find.widgetWithText(AppButton, 'Выберите аудио'), findsOneWidget);
  });

  testWidgets('with no cap (limit 0) the balance is not shown', (
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
  testWidgets('voice-over unavailable (503) offers a retry', (
    tester,
  ) async {
    await pumpForm(
      tester,
      ttsError: const ApiException(
        code: ApiErrorCode.ttsUnavailable,
        message: 'service is not configured',
        status: 503,
      ),
      text: 'Hello there',
    );

    await startSynthesis(tester);

    expect(
      find.text('Озвучка временно недоступна. Попробуйте позже.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Повторить'), findsOneWidget);
  });

  testWidgets('the quota is exhausted (429): it offers a file upload and no retry', (
    tester,
  ) async {
    await pumpForm(
      tester,
      ttsError: const ApiException(
        code: ApiErrorCode.ttsQuotaExceeded,
        message: 'The free voice-over quota for this month is used up',
        status: 429,
      ),
      text: 'Hello there',
    );

    await startSynthesis(tester);

    expect(
      find.text('The free voice-over quota for this month is used up'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Загрузить файл'), findsOneWidget);
    // A rate limit is not auto-retried, so no retry button here.
    expect(find.widgetWithText(AppButton, 'Повторить'), findsNothing);
  });
}
