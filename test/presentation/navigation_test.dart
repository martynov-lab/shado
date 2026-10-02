import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/app.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/library_providers.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/di/settings_providers.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/lessons/domain/entities/library_root.dart';
import 'package:shado/features/lessons/domain/repositories/library_repository.dart';
import 'package:shado/features/lessons/presentation/widgets/empty_lessons_view.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_language_repository.dart';
import 'fake_lesson_repository.dart';

class _EmptyLibrary implements LibraryRepository {
  @override
  Future<LibraryRoot> getRoot() async => LibraryRoot.empty;
}

class _FakeProgressRemote implements ProgressRemoteDataSource {
  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) async => ProgressSummary.fromJson(const {});

  @override
  Future<ProgressSummary> getSummary() async =>
      ProgressSummary.fromJson(const {});

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async => const [];
}

class _FakeServerSettings implements SettingsRemoteDataSource {
  @override
  Future<int> getCompletionReps() async => 10;

  @override
  Future<int> setCompletionReps(int reps) async => reps;
}

/// Moving between sections, signing in and out through the router.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<FakeAuthRepository> pumpApp(
    WidgetTester tester, {
    AuthUser? user,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = FakeAuthRepository(user: user);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          lessonRepositoryProvider.overrideWithValue(FakeLessonRepository()),
          libraryRepositoryProvider.overrideWithValue(_EmptyLibrary()),
          languageRepositoryProvider.overrideWithValue(
            const FakeLanguageRepository([]),
          ),
          progressRemoteDataSourceProvider.overrideWithValue(
            _FakeProgressRemote(),
          ),
          settingsRemoteDataSourceProvider.overrideWithValue(
            _FakeServerSettings(),
          ),
        ],
        child: const ShadoApp(),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('a signed-in user moves between every section', (tester) async {
    await pumpApp(tester, user: testUser(role: UserRole.owner));

    expect(find.textContaining('Hi, '), findsOneWidget);

    await openTab(tester, 'Lessons');
    expect(find.byType(EmptyLessonsView), findsOneWidget);

    await openTab(tester, 'Progress');
    expect(find.text('Minutes per day'), findsOneWidget);

    await openTab(tester, 'Settings');
    expect(find.text('Playback'.toUpperCase()), findsOneWidget);

    await openTab(tester, 'Add');
    expect(find.text('New lesson'), findsOneWidget);

    await openTab(tester, 'Home');
    expect(find.textContaining('Hi, '), findsOneWidget);
  });

  testWidgets('without a session the login screen opens', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('signing in leads home, signing out back to login', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Hi, '), findsOneWidget);

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
