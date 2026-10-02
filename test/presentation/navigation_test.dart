import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/app.dart';
import 'package:shado/core/network/network_monitor.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/core_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/library_providers.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/di/settings_providers.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/lessons/domain/entities/library_root.dart';
import 'package:shado/features/lessons/domain/repositories/library_repository.dart';
import 'package:shado/features/lessons/presentation/widgets/empty_lessons_view.dart';
import 'package:shado/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/domain/entities/pending_events.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_language_repository.dart';
import 'fake_lesson_repository.dart';

/// Network status driven by the test; starts as [online].
class _FakeNetworkMonitor implements NetworkMonitor {
  _FakeNetworkMonitor({this.online = true});

  final bool online;
  final StreamController<bool> changes = StreamController.broadcast();

  @override
  Stream<bool> get onlineChanges => changes.stream;

  @override
  Future<bool> isOnline() async => online;
}

class _EmptyLibrary implements LibraryRepository {
  @override
  Future<LibraryRoot> getRoot() async => LibraryRoot.empty;
}

/// Progress on the device without a database: nothing studied yet.
class _EmptyProgressLocal implements ProgressLocalDataSource {
  ProgressSummary? _summary;
  List<ProgressDay>? _history;

  @override
  Future<void> bumpSegment(String lessonId, int segmentIndex) => Future.value();

  @override
  Future<void> addListened(int ms) => Future.value();

  @override
  Future<Map<int, int>> readReps(String lessonId) async => const {};

  @override
  Future<PendingEvents> readPending() async => PendingEvents.empty;

  @override
  Future<void> subtractPending(int listenedMs, int segmentRepeats) =>
      Future.value();

  @override
  Future<bool> isCompletedSent(String lessonId) async => false;

  @override
  Future<void> markCompletedSent(String lessonId) => Future.value();

  @override
  Future<ProgressSummary?> readSummary() async => _summary;

  @override
  Future<void> saveSummary(ProgressSummary summary) async => _summary = summary;

  @override
  Future<List<ProgressDay>?> readHistory() async => _history;

  @override
  Future<void> saveHistory(List<ProgressDay> days) async => _history = days;

  @override
  Future<void> clear() => Future.value();
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
    NetworkMonitor? network,
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
          progressLocalDataSourceProvider.overrideWithValue(
            _EmptyProgressLocal(),
          ),
          settingsRemoteDataSourceProvider.overrideWithValue(
            _FakeServerSettings(),
          ),
          networkMonitorProvider.overrideWithValue(
            network ?? _FakeNetworkMonitor(),
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

  testWidgets('offline the banner shows and the add section hides', (
    tester,
  ) async {
    final network = _FakeNetworkMonitor(online: false);
    addTearDown(network.changes.close);
    await pumpApp(
      tester,
      user: testUser(role: UserRole.owner),
      network: network,
    );

    expect(
      find.text('Offline — downloaded lessons are available'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Add'), findsNothing);

    network.changes.add(true);
    await tester.pumpAndSettle();

    expect(
      find.text('Offline — downloaded lessons are available'),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Add'), findsWidgets);
  });
}
