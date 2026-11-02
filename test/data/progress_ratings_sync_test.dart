import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/features/progress/data/datasources/progress_local_datasource_sqflite.dart';
import 'package:shado/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:shado/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:shado/features/progress/domain/entities/item_rating.dart';
import 'package:shado/features/progress/domain/entities/progress_summary.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A rating server: records sent batches and answers the delta it holds.
class _FakeRatingsRemote implements ProgressRemoteDataSource {
  final List<List<ItemRating>> sent = [];
  final List<String?> deltaRequests = [];
  List<ItemRating> delta = const [];
  String serverTime = '2026-11-02T12:00:00.000Z';
  ApiException? putError;

  @override
  Future<int> putRatings(List<ItemRating> ratings) async {
    sent.add(List.of(ratings));
    final error = putError;
    if (error != null) throw error;
    return ratings.length;
  }

  @override
  Future<({List<ItemRating> ratings, String serverTime})> getRatings({
    String? since,
  }) async {
    deltaRequests.add(since);
    return (ratings: delta, serverTime: serverTime);
  }

  @override
  Future<ProgressSummary> getSummary() async =>
      ProgressSummary.fromJson(const {});

  @override
  Future<List<ProgressDay>> getHistory({int days = 70}) async => const [];

  @override
  Future<ProgressSummary> reportEvents({
    int? listenedMs,
    int? segmentRepeats,
    String? lessonId,
    bool? completed,
  }) async => ProgressSummary.fromJson(const {});
}

ItemRating _rating(String key, int stars, DateTime at, {String lesson = 'l1'}) =>
    ItemRating(lessonId: lesson, itemKey: key, stars: stars, ratedAt: at);

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final early = DateTime.utc(2026, 11, 2, 10);
  final late = DateTime.utc(2026, 11, 2, 11);
  var dbCounter = 0;

  ({
    SqfliteProgressLocalDataSource local,
    _FakeRatingsRemote remote,
    ProgressRepositoryImpl repository,
  })
  build() {
    final name = 'ratings_test_${dbCounter++}.db';
    final local = SqfliteProgressLocalDataSource(databaseName: name);
    final remote = _FakeRatingsRemote();
    addTearDown(() async {
      await local.clear();
      await databaseFactory.deleteDatabase(
        '${await databaseFactory.getDatabasesPath()}/$name',
      );
    });
    return (
      local: local,
      remote: remote,
      repository: ProgressRepositoryImpl(local: local, remote: remote),
    );
  }

  test('saved ratings are read back, a zero removes the rating', () async {
    final env = build();
    await env.repository.saveRatings([
      _rating('s:a', 4, early),
      _rating('s:b', 2, early),
    ]);
    await env.repository.saveRatings([_rating('s:b', 0, late)]);

    expect(await env.repository.readStars('l1'), {'s:a': 4});
  });

  test('sync sends the queue once and pulls the delta', () async {
    final env = build();
    await env.repository.saveRatings([_rating('s:a', 5, early)]);
    env.remote.delta = [_rating('p:x', 3, early, lesson: 'l2')];

    final changed = await env.repository.syncRatings();
    await env.repository.syncRatings();

    expect(env.remote.sent, hasLength(1));
    expect(env.remote.sent.single.single.stars, 5);
    expect(changed, {'l2'});
    expect(await env.repository.readStars('l2'), {'p:x': 3});
    // The second delta starts from the server time of the first.
    expect(env.remote.deltaRequests, [null, '2026-11-02T12:00:00.000Z']);
  });

  test('a newer local rating is not overwritten by an older one', () async {
    final env = build();
    await env.repository.saveRatings([_rating('s:a', 2, late)]);
    env.remote.delta = [_rating('s:a', 5, early)];

    await env.repository.syncRatings();

    expect(await env.repository.readStars('l1'), {'s:a': 2});
  });

  test('a newer server rating replaces the local one', () async {
    final env = build();
    await env.local.applyServerRatings([_rating('s:a', 2, early)]);
    env.remote.delta = [_rating('s:a', 0, late)];

    final changed = await env.repository.syncRatings();

    expect(changed, {'l1'});
    expect(await env.repository.readStars('l1'), isEmpty);
  });

  test('a batch rejected as invalid leaves the queue', () async {
    final env = build();
    await env.repository.saveRatings([_rating('bad', 3, early)]);
    env.remote.putError = const ApiException(
      code: ApiErrorCode.validationError,
      message: 'bad key',
      status: 422,
    );

    await env.repository.syncRatings();
    env.remote.putError = null;
    await env.repository.syncRatings();

    expect(env.remote.sent, hasLength(1));
  });

  test('a network failure keeps the queue for the next sync', () async {
    final env = build();
    await env.repository.saveRatings([_rating('s:a', 3, early)]);
    env.remote.putError = const ApiException(
      code: ApiErrorCode.internalError,
      message: 'down',
      status: 500,
    );

    await expectLater(env.repository.syncRatings(), throwsA(isA<ApiException>()));
    env.remote.putError = null;
    await env.repository.syncRatings();

    expect(env.remote.sent, hasLength(2));
  });

  test('a rating changed during the request stays queued', () async {
    final env = build();
    await env.repository.saveRatings([_rating('s:a', 3, early)]);
    final sent = await env.local.readQueuedRatings(limit: 10);
    await env.repository.saveRatings([_rating('s:a', 4, late)]);

    await env.local.markRatingsSent(sent);

    final queued = await env.local.readQueuedRatings(limit: 10);
    expect(queued.single.stars, 4);
  });
}
