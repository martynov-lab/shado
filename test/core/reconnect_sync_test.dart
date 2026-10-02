import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/bootstrap/reconnect_sync.dart';
import 'package:shado/core/network/network_monitor.dart';
import 'package:shado/core/network/network_status.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';
import 'package:shado/features/auth/domain/services/auth_service.dart';
import 'package:shado/features/auth/domain/usecases/sign_in.dart';
import 'package:shado/features/lessons/domain/entities/library_root.dart';
import 'package:shado/features/lessons/domain/repositories/library_repository.dart';
import 'package:shado/features/lessons/domain/services/lesson_catalog_service.dart';
import 'package:shado/features/lessons/domain/usecases/delete_lesson.dart';
import 'package:shado/features/lessons/domain/usecases/get_lessons.dart';
import 'package:shado/features/lessons/domain/usecases/get_library.dart';
import 'package:shado/features/lessons/domain/usecases/sync_lessons.dart';
import 'package:shado/features/progress/domain/entities/pending_events.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:shado/features/progress/domain/repositories/progress_repository.dart';
import 'package:shado/features/progress/domain/services/progress_reporter.dart';
import 'package:shado/features/progress/domain/services/progress_summary_service.dart';

import '../presentation/fake_auth_repository.dart';
import '../presentation/fake_lesson_repository.dart';

/// Connectivity driven by the test; starts offline.
class _FakeNetworkMonitor implements NetworkMonitor {
  final StreamController<bool> changes = StreamController.broadcast();

  @override
  Stream<bool> get onlineChanges => changes.stream;

  @override
  Future<bool> isOnline() async => false;
}

/// Counts lesson syncs.
class _CountingLessonRepository extends FakeLessonRepository {
  int syncs = 0;

  @override
  Future<void> syncLessons({String language = ''}) async => syncs++;
}

class _EmptyLibrary implements LibraryRepository {
  @override
  Future<LibraryRoot> getRoot() async => LibraryRoot.empty;
}

/// Activity collected offline and a server that accepts it.
class _FakeProgressRepository implements ProgressRepository {
  int reports = 0;
  int summaries = 0;

  @override
  Future<PendingEvents> readPending() async =>
      const PendingEvents(listenedMs: 60000, segmentRepeats: 2);

  @override
  Future<void> subtractPending(int listenedMs, int segmentRepeats) =>
      Future.value();

  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) async {
    reports++;
    return ProgressSummary.fromJson(const {});
  }

  @override
  Future<ProgressSummary> getSummary() async {
    summaries++;
    return ProgressSummary.fromJson(const {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  group('$ReconnectSync', () {
    test('a reconnect syncs lessons and sends offline progress', () async {
      final setup = await _setUp(testUser());

      setup.network.changes.add(true);
      await pumpEventQueue();

      expect(setup.lessons.syncs, equals(1));
      expect(setup.progress.reports, equals(1));
      expect(setup.progress.summaries, equals(1));
    });

    test('without a session a reconnect does nothing', () async {
      final setup = await _setUp(null);

      setup.network.changes.add(true);
      await pumpEventQueue();

      expect(setup.lessons.syncs, equals(0));
      expect(setup.progress.reports, equals(0));
    });
  });
}

Future<
  ({
    _FakeNetworkMonitor network,
    _CountingLessonRepository lessons,
    _FakeProgressRepository progress,
  })
>
_setUp(AuthUser? user) async {
  final monitor = _FakeNetworkMonitor();
  final network = NetworkStatus(monitor);
  final AuthRepository authRepository = FakeAuthRepository(user: user);
  final auth = AuthService(
    repository: authRepository,
    signIn: SignIn(authRepository),
    signUp: SignUp(authRepository),
    signOut: SignOut(authRepository),
    getCurrentUser: GetCurrentUser(authRepository),
    updateProfile: UpdateProfile(authRepository),
    network: monitor,
  );
  await auth.restore();
  final lessons = _CountingLessonRepository();
  final catalog = LessonCatalogService(
    getLessons: GetLessons(lessons),
    syncLessons: SyncLessons(lessons),
    deleteLesson: DeleteLesson(lessons),
    getLibrary: GetLibrary(_EmptyLibrary()),
    auth: auth,
  );
  final progress = _FakeProgressRepository();
  final summary = ProgressSummaryService(progress);
  final sync = ReconnectSync(
    network: network,
    auth: auth,
    catalog: catalog,
    reporter: ProgressReporter(repository: progress, summary: summary),
    progressSummary: summary,
  );
  // Let the initial offline status settle before the test goes online.
  await pumpEventQueue();
  addTearDown(() {
    sync.dispose();
    summary.dispose();
    catalog.dispose();
    auth.dispose();
    network.dispose();
    return monitor.changes.close();
  });
  return (network: monitor, lessons: lessons, progress: progress);
}
