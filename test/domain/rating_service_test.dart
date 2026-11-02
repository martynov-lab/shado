import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/network_monitor.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';
import 'package:shado/features/auth/domain/services/auth_service.dart';
import 'package:shado/features/auth/domain/usecases/sign_in.dart';
import 'package:shado/features/progress/domain/services/progress_reporter.dart';
import 'package:shado/features/progress/domain/services/progress_summary_service.dart';
import 'package:shado/features/progress/domain/services/rating_service.dart';

import '../presentation/fake_auth_repository.dart';
import 'fake_progress_repository.dart';

class _OnlineMonitor implements NetworkMonitor {
  @override
  Stream<bool> get onlineChanges => const Stream.empty();

  @override
  Future<bool> isOnline() async => true;
}

Future<({RatingService ratings, FakeProgressRepository progress})> _setUp({
  bool signedIn = true,
}) async {
  final AuthRepository authRepository = FakeAuthRepository(
    user: signedIn ? testUser() : null,
  );
  final auth = AuthService(
    repository: authRepository,
    signIn: SignIn(authRepository),
    signUp: SignUp(authRepository),
    signOut: SignOut(authRepository),
    getCurrentUser: GetCurrentUser(authRepository),
    updateProfile: UpdateProfile(authRepository),
    network: _OnlineMonitor(),
  );
  await auth.restore();
  final progress = FakeProgressRepository();
  final summary = ProgressSummaryService(progress);
  final ratings = RatingService(
    repository: progress,
    reporter: ProgressReporter(repository: progress, summary: summary),
    summary: summary,
    auth: auth,
  );
  addTearDown(() {
    ratings.dispose();
    summary.dispose();
    auth.dispose();
  });
  await pumpEventQueue();
  return (ratings: ratings, progress: progress);
}

void main() {
  test('a signed-in user gets the ratings synced at start', () async {
    final setup = await _setUp();

    expect(setup.progress.syncCount, greaterThanOrEqualTo(1));
  });

  test('rate saves every key, announces the lesson and syncs', () async {
    final setup = await _setUp();
    final before = setup.progress.syncCount;
    final changes = <String>[];
    final subscription = setup.ratings.changes.listen(changes.add);
    addTearDown(subscription.cancel);

    await setup.ratings.rate(
      lessonId: 'l1',
      itemKeys: const ['s:a', 's:b'],
      stars: 4,
      lessonItemKeys: const ['s:a', 's:b', 's:c'],
    );
    await pumpEventQueue();

    expect(await setup.ratings.starsOf('l1'), {'s:a': 4, 's:b': 4});
    expect(changes, ['l1']);
    expect(setup.progress.syncCount, greaterThan(before));
  });

  test('five stars on every item report the lesson as completed', () async {
    final setup = await _setUp();

    await setup.ratings.rate(
      lessonId: 'l1',
      itemKeys: const ['s:a', 's:b'],
      stars: 5,
      lessonItemKeys: const ['s:a', 's:b'],
    );
    await pumpEventQueue();

    expect(setup.progress.events.where((e) => e.completed == true), hasLength(1));
  });

  test('lessons changed on another device are announced', () async {
    final setup = await _setUp();
    final changes = <String>[];
    final subscription = setup.ratings.changes.listen(changes.add);
    addTearDown(subscription.cancel);
    setup.progress.serverChanges = {'l7'};

    await setup.ratings.sync();

    expect(changes, ['l7']);
  });

  test('a failed sync is swallowed and keeps the service usable', () async {
    final setup = await _setUp();
    setup.progress.throwOnSync = true;

    await setup.ratings.sync();
    setup.progress.throwOnSync = false;
    await setup.ratings.sync();

    expect(setup.progress.syncCount, greaterThanOrEqualTo(3));
  });

  test('without a session nothing is synced at start', () async {
    final setup = await _setUp(signedIn: false);

    expect(setup.progress.syncCount, 0);
  });
}
