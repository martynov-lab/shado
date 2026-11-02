import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_kind.dart';
import 'package:shado/features/lessons/domain/entities/phrase.dart';
import 'package:shado/features/lessons/presentation/screens/phrase_set/phrase_set_page.dart';
import 'package:shado/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/domain/entities/item_rating.dart';
import 'package:shado/features/progress/domain/entities/pending_events.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_lesson_repository.dart';

/// Ratings and counters in memory instead of `progress.db`.
class _MemoryProgressLocal implements ProgressLocalDataSource {
  final Map<String, int> stars = {};

  @override
  Future<Map<String, int>> readStars(String lessonId) async => {
    for (final MapEntry(:key, :value) in stars.entries)
      if (value > 0) key: value,
  };

  @override
  Future<void> saveRatings(List<ItemRating> ratings) async {
    for (final rating in ratings) {
      stars[rating.itemKey] = rating.stars;
    }
  }

  @override
  Future<List<ItemRating>> readQueuedRatings({required int limit}) async =>
      const [];

  @override
  Future<PendingEvents> readPending() async => PendingEvents.empty;

  @override
  Future<bool> isCompletedSent(String lessonId) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _OfflineProgressRemote implements ProgressRemoteDataSource {
  @override
  Future<ProgressSummary> getSummary() async =>
      ProgressSummary.fromJson(const {});

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(UnimplementedError());
}

final _set = Lesson(
  id: 'set-1',
  title: 'At the airport',
  audioPath: '',
  durationMs: 0,
  createdAt: DateTime.utc(2026, 11, 2),
  segments: const [],
  kind: LessonKind.expressions,
  isPublic: false,
  phrases: const [
    Phrase(
      id: 'p0',
      text: 'Where is the check-in desk?',
      translations: {'ru': 'Где стойка регистрации?'},
      audioId: 'a0',
      durationMs: 1000,
    ),
    Phrase(
      id: 'p1',
      text: "I'd like a window seat.",
      translations: {'ru': 'Я бы хотел место у окна.'},
      audioId: 'a1',
      durationMs: 1000,
    ),
  ],
);

void main() {
  late _MemoryProgressLocal progressLocal;

  Future<void> pumpPage(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    progressLocal = _MemoryProgressLocal();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: testUser()),
          ),
          lessonRepositoryProvider.overrideWithValue(
            FakeLessonRepository(lessons: [_set]),
          ),
          progressLocalDataSourceProvider.overrideWithValue(progressLocal),
          progressRemoteDataSourceProvider.overrideWithValue(
            _OfflineProgressRemote(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const PhraseSetPage(lessonId: 'set-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Listen shows the phrase with its translation', (tester) async {
    await pumpPage(tester);

    expect(find.text('Where is the check-in desk?'), findsOneWidget);
    expect(find.text('Где стойка регистрации?'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('Recall hides the phrase until the card is flipped', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Recall'));
    await tester.pumpAndSettle();

    expect(find.text('Где стойка регистрации?'), findsOneWidget);
    expect(find.text('Where is the check-in desk?'), findsNothing);
    expect(find.byType(AppStarRating), findsNothing);

    await tester.tap(find.text('Flip'));
    await tester.pumpAndSettle();

    expect(find.text('Where is the check-in desk?'), findsOneWidget);
    expect(find.text('How well do you know it?'), findsOneWidget);
  });

  testWidgets('a star rates the phrase on the card', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsLabel('4 of 5'));
    await tester.pumpAndSettle();

    expect(progressLocal.stars, {'p:p0': 4});
  });

  testWidgets('next goes to the second phrase', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsLabel('Next phrase'));
    await tester.pumpAndSettle();

    expect(find.text("I'd like a window seat."), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });
}
