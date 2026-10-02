import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_download.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shado/features/lessons/domain/services/lesson_download_service.dart';

/// Downloads in memory; [transfer] decides how the audio transfer goes.
class _FakeLessonRepository implements LessonRepository {
  final Set<String> downloaded = {};

  /// Runs inside `downloadLesson` with its progress callback.
  Future<void> Function(void Function(int received, int total) onProgress)
  transfer = (_) => Future.value();

  @override
  Future<Set<String>> downloadedLessonIds() async => Set.of(downloaded);

  @override
  Future<void> downloadLesson(
    String id, {
    void Function(int received, int total)? onProgress,
  }) async {
    // The fake always passes a callback through.
    // ignore: no-empty-block
    await transfer(onProgress ?? (_, _) {});
    downloaded.add(id);
  }

  @override
  Future<void> removeDownload(String id) async => downloaded.remove(id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  group('$LessonDownloadService', () {
    test('load reports lessons downloaded earlier', () async {
      final repository = _FakeLessonRepository()..downloaded.add('a');
      final service = _makeService(repository);

      await service.load();

      expect(service.stateOf('a'), isA<Downloaded>());
      expect(service.stateOf('b'), isA<NotDownloaded>());
    });

    test('download goes through progress and ends downloaded', () async {
      final repository = _FakeLessonRepository();
      final service = _makeService(repository);
      final gate = Completer<void>();
      repository.transfer = (onProgress) async {
        onProgress(50, 100);
        await gate.future;
      };

      final download = service.download('a');
      await pumpEventQueue();

      expect(
        service.stateOf('a'),
        isA<Downloading>().having((d) => d.progress, 'progress', 0.5),
      );

      gate.complete();
      await download;

      expect(service.stateOf('a'), isA<Downloaded>());
      expect(service.downloadedIds, equals({'a'}));
    });

    test('a failed download leaves the lesson not downloaded', () async {
      final repository = _FakeLessonRepository()
        ..transfer = (_) async => throw const NetworkFailure('offline');
      final service = _makeService(repository);

      await expectLater(service.download('a'), throwsA(isA<NetworkFailure>()));

      expect(service.stateOf('a'), isA<NotDownloaded>());
    });

    test('remove makes the lesson not downloaded', () async {
      final repository = _FakeLessonRepository()..downloaded.add('a');
      final service = _makeService(repository);
      await service.load();

      await service.remove('a');

      expect(service.stateOf('a'), isA<NotDownloaded>());
      expect(repository.downloaded, isEmpty);
    });

    test('a catalog change re-reads the downloads', () async {
      final repository = _FakeLessonRepository()..downloaded.add('a');
      final catalog = StreamController<List<Lesson>>.broadcast();
      addTearDown(catalog.close);
      final service = _makeService(repository, catalogChanges: catalog.stream);
      await service.load();

      repository.downloaded.clear();
      catalog.add(const []);
      await pumpEventQueue();

      expect(service.stateOf('a'), isA<NotDownloaded>());
    });
  });
}

LessonDownloadService _makeService(
  LessonRepository repository, {
  Stream<List<Lesson>> catalogChanges = const Stream.empty(),
}) {
  final service = LessonDownloadService(
    repository: repository,
    catalogChanges: catalogChanges,
  );
  addTearDown(service.dispose);
  return service;
}
