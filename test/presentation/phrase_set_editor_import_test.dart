import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/translation_providers.dart';
import 'package:shado/features/languages/domain/entities/language.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/tts_quota.dart';
import 'package:shado/features/lessons/domain/usecases/get_topics.dart';
import 'package:shado/features/lessons/domain/usecases/get_tts_quota.dart';
import 'package:shado/features/lessons/presentation/screens/phrase_set_editor/phrase_set_editor_page.dart';
import 'package:shado/features/lessons/presentation/widgets/phrase_draft_row.dart';
import 'package:shado/features/translation/data/datasources/translation_remote_datasource.dart';
import 'package:shado/features/translation/domain/entities/translation_language.dart';
import 'package:shado/theme/theme.dart';

import 'fake_auth_repository.dart';
import 'fake_language_repository.dart';

class _NoTopics implements GetTopics {
  @override
  Future<List<Topic>> call() async => const [];
}

class _Quota implements GetTtsQuota {
  @override
  Future<TtsQuota> call() async => const TtsQuota(
    provider: 'gemini',
    day: TtsQuotaWindow(used: 0, limit: 14, remaining: 14),
    minute: TtsQuotaWindow(used: 0, limit: 2, remaining: 2),
  );
}

/// Translates by prefixing the language and records every batch.
class _FakeTranslationRemote implements TranslationRemoteDataSource {
  final List<List<String>> batches = [];

  @override
  Future<List<TranslationLanguage>> languages() async => const [
    TranslationLanguage(code: 'ru', name: 'Russian'),
  ];

  @override
  Future<List<String>> translate(
    List<String> texts, {
    required String sourceLang,
  }) async {
    batches.add(texts);
    return [for (final text in texts) 'ru: $text'];
  }
}

void main() {
  late _FakeTranslationRemote translation;

  Future<void> pumpEditor(WidgetTester tester) async {
    translation = _FakeTranslationRemote();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: testUser()),
        ),
        languageRepositoryProvider.overrideWithValue(
          FakeLanguageRepository(const [Language(code: 'en', name: 'English')]),
        ),
        getTopicsProvider.overrideWithValue(_NoTopics()),
        getTtsQuotaProvider.overrideWithValue(_Quota()),
        translationRemoteDataSourceProvider.overrideWithValue(translation),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authServiceProvider).restore();
    tester.view
      ..physicalSize = const Size(1000, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const PhraseSetEditorPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> paste(WidgetTester tester, String text) async {
    await tester.tap(find.text('Paste text'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(EditableText),
      ),
      text,
    );
    await tester.tap(find.text('Split into phrases'));
    await tester.pumpAndSettle();
  }

  testWidgets('pasted text becomes phrases translated in one batch', (
    tester,
  ) async {
    await pumpEditor(tester);

    await paste(tester, 'Where is the desk. I would like\na window seat.');

    final rows = tester.widgetList<PhraseDraftRow>(find.byType(PhraseDraftRow));
    expect(rows.map((row) => row.text), [
      'Where is the desk.',
      'I would like a window seat.',
    ]);
    expect(rows.map((row) => row.translation), [
      'ru: Where is the desk.',
      'ru: I would like a window seat.',
    ]);
    expect(translation.batches, [
      ['Where is the desk.', 'I would like a window seat.'],
    ]);
  });

  testWidgets('a second paste adds to the phrases already there', (
    tester,
  ) async {
    await pumpEditor(tester);
    await paste(tester, 'One.');

    await paste(tester, 'Two. Three.');

    final rows = tester.widgetList<PhraseDraftRow>(find.byType(PhraseDraftRow));
    expect(rows.map((row) => row.text), ['One.', 'Two.', 'Three.']);
    // Already translated phrases are not sent again.
    expect(translation.batches.last, ['Two.', 'Three.']);
  });
}
