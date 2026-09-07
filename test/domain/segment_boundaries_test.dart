import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/features/lessons/domain/entities/audio_trim.dart';
import 'package:shado/features/lessons/domain/entities/segment_boundaries.dart';

void main() {
  const full = AudioTrim.full(9000);

  /// A trimmed track: the first and last seconds are cut off.
  const trimmed = AudioTrim(startMs: 1000, endMs: 8000);

  group('SegmentBoundaries.even', () {
    test('splits the audio evenly and back to back', () {
      expect(SegmentBoundaries.even(3, full), [0, 3000, 6000, 9000]);
    });

    test('without segments or duration there are no boundaries', () {
      expect(SegmentBoundaries.even(0, full), isEmpty);
      expect(SegmentBoundaries.even(3, const AudioTrim.full(0)), isEmpty);
    });

    test('on a trimmed track it splits only the remaining range', () {
      expect(SegmentBoundaries.even(2, trimmed), [1000, 4500, 8000]);
    });
  });

  group('SegmentBoundaries.resize', () {
    test('keeps the markup as is when the segment count did not change', () {
      final current = [0, 1000, 7000, 9000];

      expect(SegmentBoundaries.resize(current, 3, full), current);
    });

    test('adding a segment keeps the markers already placed', () {
      final result = SegmentBoundaries.resize([0, 1000, 7000, 9000], 4, full);

      expect(result.take(3), [0, 1000, 7000]);
      expect(result.length, 5);
      expect(result.last, 9000);
    });

    test('removing a segment keeps the markers from the start', () {
      final result = SegmentBoundaries.resize([0, 1000, 7000, 9000], 2, full);

      expect(result, [0, 1000, 9000]);
    });

    test('lays out empty markup evenly', () {
      expect(SegmentBoundaries.resize(const [], 3, full), [
        0,
        3000,
        6000,
        9000,
      ]);
    });

    test('spreads markers by at least kMinSegmentGapMs', () {
      final result = SegmentBoundaries.resize([0, 100], 3, const AudioTrim.full(600));

      for (var i = 1; i < result.length; i++) {
        expect(result[i] - result[i - 1], greaterThanOrEqualTo(1));
      }
      expect(result.first, 0);
      expect(result.last, 600);
      expect(result[1], greaterThanOrEqualTo(kMinSegmentGapMs));
    });

    test('carries whole-file markup over to a trimmed track', () {
      // Markers outside the trim are pulled inside; the one inside stays.
      final result = SegmentBoundaries.resize(
        [0, 500, 4000, 8500, 9000],
        4,
        trimmed,
      );

      expect(result.first, 1000);
      expect(result.last, 8000);
      expect(result[2], 4000);
      for (var i = 1; i < result.length; i++) {
        expect(result[i] - result[i - 1], greaterThanOrEqualTo(kMinSegmentGapMs));
      }
    });
  });

  group('SegmentBoundaries.refit', () {
    test('markers inside the range stay where they are', () {
      final result = SegmentBoundaries.refit([0, 3000, 6000, 9000], trimmed);

      expect(result, [1000, 3000, 6000, 8000]);
    });

    test('trimming the tail does not collapse the markers that lost their place', () {
      // Markers past the new end split the remaining space evenly.
      final result = SegmentBoundaries.refit(
        [0, 3000, 6000, 7500, 9000],
        const AudioTrim(startMs: 0, endMs: 5000),
      );

      expect(result.length, 5);
      expect(result, [0, 3000, 3666, 4333, 5000]);
    });

    test('trimming the head does not collapse the markers that lost their place', () {
      final result = SegmentBoundaries.refit(
        [0, 1000, 2000, 7000, 9000],
        const AudioTrim(startMs: 4000, endMs: 9000),
      );

      expect(result.length, 5);
      expect(result.first, 4000);
      expect(result.last, 9000);
      // 7000 survived while 1000 and 2000 split the head before it.
      expect(result[3], 7000);
      expect(result, [4000, 5000, 6000, 7000, 9000]);
    });

    test('segments never degenerate, even when everything fell outside the edges', () {
      final result = SegmentBoundaries.refit(
        [0, 1000, 2000, 3000, 9000],
        const AudioTrim(startMs: 5000, endMs: 8000),
      );

      expect(result.first, 5000);
      expect(result.last, 8000);
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i] - result[i - 1],
          greaterThanOrEqualTo(kMinSegmentGapMs),
        );
      }
    });

    test('a single segment takes up the whole range', () {
      expect(SegmentBoundaries.refit([0, 9000], trimmed), [1000, 8000]);
    });
  });

  group('SegmentBoundaries.normalize', () {
    test('pins the outer boundaries to the edges of the audio', () {
      final result = SegmentBoundaries.normalize([500, 3000, 8000], full);

      expect(result.first, 0);
      expect(result.last, 9000);
    });

    test('pins the outer boundaries to the edges of the trim', () {
      final result = SegmentBoundaries.normalize([0, 3000, 9000], trimmed);

      expect(result.first, 1000);
      expect(result.last, 8000);
      expect(result[1], 3000);
    });

    test('spreads neighbouring boundaries by at least kMinSegmentGapMs', () {
      final result = SegmentBoundaries.normalize([0, 1000, 1000, 9000], full);

      expect(result[2] - result[1], greaterThanOrEqualTo(kMinSegmentGapMs));
    });

    test('does not let a marker run past the right edge', () {
      final result = SegmentBoundaries.normalize([0, 8990, 8995, 9000], full);

      expect(result[1], lessThan(result[2]));
      expect(result[2], lessThan(9000));
    });

    test('leaves valid boundaries untouched', () {
      final input = [0, 3000, 6000, 9000];

      expect(SegmentBoundaries.normalize(input, full), input);
    });

    test('on a short range it squeezes the gap but keeps the order', () {
      // Five 200 ms segments do not fit in 600 ms, so the gap gives way.
      final result = SegmentBoundaries.normalize(
        [0, 0, 0, 0, 0, 600],
        const AudioTrim.full(600),
      );

      expect(result.first, 0);
      expect(result.last, 600);
      for (var i = 1; i < result.length; i++) {
        expect(result[i], greaterThan(result[i - 1]));
      }
    });
  });

  group('SegmentBoundaries.insertAt', () {
    test('inserts the first marker at the player position, extending the markup', () {
      final result = SegmentBoundaries.insertAt([0, 9000], 1, 2000, full);

      expect(result, [0, 2000, 9000]);
    });

    test('places the next marker at the player position, keeping the earlier ones', () {
      final result = SegmentBoundaries.insertAt([0, 3000, 9000], 2, 6000, full);

      expect(result, [0, 3000, 6000, 9000]);
    });

    test('pins the marker to the previous one when the player sits before it', () {
      // A new marker goes after the previous one with a gap, not before it.
      final result = SegmentBoundaries.insertAt([0, 4000, 9000], 2, 0, full);

      expect(result, [0, 4000, 4200, 9000]);
      expect(result[2] - result[1], kMinSegmentGapMs);
    });

    test('with the slider at the start it moves the first marker off the left edge', () {
      final result = SegmentBoundaries.insertAt([0, 9000], 1, 0, full);

      expect(result, [0, kMinSegmentGapMs, 9000]);
    });

    test('an index out of range changes nothing', () {
      const input = [0, 3000, 9000];

      expect(SegmentBoundaries.insertAt(input, 0, 1000, full), input);
      expect(SegmentBoundaries.insertAt(input, 3, 1000, full), input);
    });

    test('on a trimmed track it stays inside the remaining range', () {
      // The player at 500 is left of the range, so the marker keeps a gap.
      final result = SegmentBoundaries.insertAt([1000, 8000], 1, 500, trimmed);

      expect(result.first, 1000);
      expect(result.last, 8000);
      expect(result[1], greaterThanOrEqualTo(1000 + kMinSegmentGapMs));
    });
  });
}
