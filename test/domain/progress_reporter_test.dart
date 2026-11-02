import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/domain/entities/item_rating.dart';
import 'package:shado/features/progress/domain/repositories/progress_repository.dart';
import 'package:shado/features/progress/domain/services/progress_reporter.dart';
import 'package:shado/features/progress/domain/services/progress_summary_service.dart';

import 'fake_progress_repository.dart';

void main() {
  group('ProgressReporter.flush', () {
    test('sends what was accumulated and subtracts what was sent', () async {
      final repository = FakeProgressRepository();
      final reporter = _makeReporter(repository);
      await repository.addListened(5000);
      await reporter.recordRepeats(1);

      await reporter.flush(lessonId: 'l1');

      expect(repository.events.single.listenedMs, 5000);
      expect(repository.events.single.segmentRepeats, 1);
      expect(repository.events.single.lessonId, 'l1');
      // The delta is cleared after a successful upload.
      final pending = await repository.readPending();
      expect(pending.isEmpty, isTrue);
    });

    test('hands the fresh summary to the summary service', () async {
      final repository = FakeProgressRepository();
      final summary = ProgressSummaryService(repository);
      addTearDown(summary.dispose);
      final reporter = ProgressReporter(
        repository: repository,
        summary: summary,
      );
      await repository.addListened(1000);

      await reporter.flush();

      expect(summary.summary, isNotNull);
    });

    test('does not send an empty delta', () async {
      final repository = FakeProgressRepository();
      final reporter = _makeReporter(repository);

      await reporter.flush();

      expect(repository.events, isEmpty);
    });

    test('the delta survives a failure', () async {
      final repository = FakeProgressRepository(throwOnEvents: true);
      final reporter = _makeReporter(repository);
      await repository.addListened(3000);

      await reporter.flush();

      final pending = await repository.readPending();
      expect(pending.listenedMs, 3000);
    });
  });

  group('ProgressReporter.recordRepeats', () {
    test('adds every repeat to the daily delta', () async {
      final repository = FakeProgressRepository();
      final reporter = _makeReporter(repository);

      await reporter.recordRepeats(3);

      expect((await repository.readPending()).segmentRepeats, 3);
    });
  });

  group('ProgressReporter.reportCompletedIfDone', () {
    const keys = ['s:a', 's:b'];

    test('sends completed once every item has five stars', () async {
      final repository = FakeProgressRepository();
      final reporter = _makeReporter(repository);
      await repository.saveRatings(_ratings({'s:a': 5, 's:b': 5}));

      await reporter.reportCompletedIfDone(lessonId: 'l1', itemKeys: keys);
      await reporter.reportCompletedIfDone(lessonId: 'l1', itemKeys: keys);

      final completedEvents = repository.events
          .where((e) => e.completed == true)
          .toList();
      expect(completedEvents, hasLength(1));
      expect(await repository.isCompletedSent('l1'), isTrue);
    });

    test('a lesson with an item below five stars is not marked', () async {
      final repository = FakeProgressRepository();
      final reporter = _makeReporter(repository);
      await repository.saveRatings(_ratings({'s:a': 5, 's:b': 4}));

      await reporter.reportCompletedIfDone(lessonId: 'l1', itemKeys: keys);

      expect(repository.events.where((e) => e.completed == true), isEmpty);
      expect(await repository.isCompletedSent('l1'), isFalse);
    });
  });
}

List<ItemRating> _ratings(Map<String, int> stars) => [
  for (final MapEntry(:key, :value) in stars.entries)
    ItemRating(
      lessonId: 'l1',
      itemKey: key,
      stars: value,
      ratedAt: DateTime.utc(2026, 11, 2),
    ),
];

ProgressReporter _makeReporter(ProgressRepository repository) {
  final summary = ProgressSummaryService(repository);
  addTearDown(summary.dispose);
  return ProgressReporter(repository: repository, summary: summary);
}
