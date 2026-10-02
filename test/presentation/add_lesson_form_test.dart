import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/languages/domain/entities/language.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/tts_quota.dart';
import 'package:shado/features/lessons/domain/usecases/get_topics.dart';
import 'package:shado/features/lessons/domain/usecases/get_tts_quota.dart';
import 'package:shado/features/lessons/domain/usecases/synthesize_tts.dart';
import 'package:shado/features/lessons/presentation/screens/add_lesson/add_lesson_form.dart';
import 'package:shado/features/lessons/presentation/screens/add_lesson/add_lesson_form_state.dart';
import 'package:shado/features/lessons/presentation/screens/add_lesson/add_lesson_page.dart';
import 'package:shado/features/lessons/presentation/widgets/segment_splitter/segment_splitter_field.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'fake_auth_repository.dart';
import 'fake_language_repository.dart';

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

/// A topic directory that answers with [topics] or fails with [error].
class _FakeTopics implements GetTopics {
  const _FakeTopics(this.topics, {this.error});

  final List<Topic> topics;
  final Object? error;

  @override
  Future<List<Topic>> call() async {
    if (error != null) throw error!;
    return topics;
  }
}

class _FakeQuota implements GetTtsQuota {
  const _FakeQuota(this.quota);

  final TtsQuota quota;

  @override
  Future<TtsQuota> call() async => quota;
}

/// Lesson creation screen: accent, level and topic pickers.
void main() {
  const topics = [
    Topic(id: 'topic-1', name: 'Education'),
    Topic(id: 'topic-2', name: 'Business'),
  ];

  // Default voice-over balance: the quota is never asked from the server.
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

  Future<void> pumpForm(
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
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            user: testUser(
              role: role,
              email: 'author@example.com',
              studiedLanguage: language.code,
            ),
          ),
        ),
        languageRepositoryProvider.overrideWithValue(
          FakeLanguageRepository([language]),
        ),
        getTopicsProvider.overrideWithValue(
          _FakeTopics(available, error: topicsError),
        ),
        getTtsQuotaProvider.overrideWithValue(_FakeQuota(quota)),
        if (ttsError != null)
          synthesizeTtsProvider.overrideWithValue(_FailingTts(ttsError)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authServiceProvider).restore();
    // Tall enough for the text field at the bottom of the form.
    tester.view
      ..physicalSize = const Size(1000, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AddLessonPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Without text the voice-over is locked.
    if (text != null) {
      await tester.enterText(
        find.descendant(
          of: find.byType(SegmentSplitterField),
          matching: find.byType(EditableText),
        ),
        text,
      );
      await tester.pumpAndSettle();
    }
  }

  /// Starts the voice-over; the voice comes from settings, so no sheet opens.
  Future<void> startSynthesis(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'Voice with AI'));
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

  testWidgets(
    'the three pickers are in place and the topic comes from the server',
    (tester) async {
      await pumpForm(tester);

      expect(find.text('Accent'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Topic'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('dropdown-topic')));
      await tester.pumpAndSettle();
      expect(find.text('Education'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('No topic'), findsWidgets);
    },
  );

  testWidgets('the chosen accent, level and topic show in the fields', (
    tester,
  ) async {
    await pumpForm(tester);

    await choose(tester, 'accent', 'British');
    await choose(tester, 'level', 'C1 — Advanced');
    await choose(tester, 'topic', 'Education');

    expect(find.text('British'), findsOneWidget);
    expect(find.text('C1'), findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
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

    expect(find.text('Accent'), findsNothing);
    expect(find.text('Level'), findsOneWidget);
  });

  testWidgets('English has the Australian accent in the list', (tester) async {
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
      find.widgetWithText(AppButton, 'Create lesson'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the topic directory failed to load and the form still works', (
    tester,
  ) async {
    await pumpForm(tester, topicsError: StateError('no connection'));

    // Accent and level do not depend on the directory: they are hardcoded.
    await choose(tester, 'accent', 'American');
    await choose(tester, 'level', 'A2 — Elementary');

    expect(find.text('American'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.textContaining('Topics failed to load'), findsOneWidget);
  });

  test('a deleted topic leaves the form', () {
    final form = AddLessonForm()..setTopic('topic-1');
    addTearDown(form.dispose);

    // The topic was deleted elsewhere and the directory came back without it.
    form.dropTopicUnless(const ['topic-2']);

    expect(form.value.topicId, isNull);
  });

  // TTS_CLIENT_SPEC §4.1: the daily voice-over balance sits by the button.
  testWidgets('the daily voice-over balance shows next to the button', (
    tester,
  ) async {
    await pumpForm(tester);

    expect(find.text('Voiceovers left today: 11'), findsOneWidget);
  });

  // Voice-over is owner-only: others get neither the button nor the hint.
  testWidgets('an author who is not the owner gets no voice-over button', (
    tester,
  ) async {
    await pumpForm(tester, role: UserRole.admin, text: 'Hello there');

    expect(find.widgetWithText(AppButton, 'Voice with AI'), findsNothing);
    expect(find.textContaining('Voiceovers left today'), findsNothing);
    // File upload stays: the author role does not lose it.
    expect(find.widgetWithText(AppButton, 'Choose audio'), findsOneWidget);
  });

  testWidgets('with no cap (limit 0) the balance is not shown', (tester) async {
    await pumpForm(
      tester,
      quota: const TtsQuota(
        provider: 'gemini',
        day: TtsQuotaWindow(used: 5, limit: 0),
        minute: TtsQuotaWindow(used: 0, limit: 2, remaining: 2),
      ),
    );

    expect(find.textContaining('Voiceovers left today'), findsNothing);
  });

  // Different voice-over error codes give different snackbar actions.
  testWidgets('voice-over unavailable (503) offers a retry', (tester) async {
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
      find.text('Voiceover is temporarily unavailable. Try again later.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Retry'), findsOneWidget);
  });

  testWidgets(
    'the quota is exhausted (429): it offers a file upload and no retry',
    (tester) async {
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
      expect(find.widgetWithText(AppButton, 'Upload a file'), findsOneWidget);
      // A rate limit is not auto-retried, so no retry button here.
      expect(find.widgetWithText(AppButton, 'Retry'), findsNothing);
    },
  );
}
