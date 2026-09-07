import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/datasources/waveform_datasource.dart';
import 'package:shado/features/lessons/data/models/waveform_peaks.dart';
import 'package:shado/features/lessons/domain/entities/audio_trim.dart';

/// Encodes values the way the server does: int8 into base64.
String encode(List<int> values) =>
    base64Encode(Int8List.fromList(values).buffer.asUint8List());

void main() {
  group('decodePeaks', () {
    test('parses base64 int8 into fractions of one', () {
      final decoded = decodePeaks(encode([127, 64, 0, -64, -127]));

      expect(decoded, hasLength(5));
      expect(decoded.first, closeTo(1.0, 0.001));
      expect(decoded[1], closeTo(0.504, 0.001));
      expect(decoded[2], 0.0);
      expect(decoded.last, closeTo(-1.0, 0.001));
    });

    test('stays within -1..1 for every int8 value', () {
      final decoded = decodePeaks(encode([for (var i = -128; i < 128; i++) i]));

      expect(decoded, hasLength(256));
      // -128/127 goes slightly past -1: a type edge, not an encoding error.
      expect(decoded.every((value) => value >= -1.008 && value <= 1.0), isTrue);
    });

    test('an empty string gives an empty waveform', () {
      expect(decodePeaks(''), isEmpty);
    });

    test('the length matches the number of points sent by the server', () {
      final peaks = WaveformPeaks.fromJson({
        'resolution': 3,
        'minima': encode([-127, -64, -10]),
        'maxima': encode([127, 64, 10]),
      });

      expect(peaks.length, 3);
      expect(peaks.maxima.every((value) => value >= 0), isTrue);
      expect(peaks.minima.every((value) => value <= 0), isTrue);
    });

    test('the actual resolution comes from the arrays, not from the field', () {
      // The point count comes from the arrays, not from `resolution`.
      final peaks = WaveformPeaks.fromJson({
        'resolution': 2000,
        'minima': encode([-127, -64]),
        'maxima': encode([127, 64]),
      });

      expect(peaks.length, 2);
    });
  });

  group('slicePeaks', () {
    final peaks = WaveformPeaks(
      minima: [for (var i = 0; i < 100; i++) -0.5],
      maxima: [for (var i = 0; i < 100; i++) i / 100],
    );

    test('without a range it returns the waveform as is', () {
      expect(slicePeaks(peaks, null, 1000).length, 100);
    });

    test('cuts out the share matching the range', () {
      final half = slicePeaks(
        peaks,
        const AudioTrim(startMs: 500, endMs: 1000),
        1000,
      );

      expect(half.length, 50);
      // The second half of the file is what must come back.
      expect(half.maxima.first, closeTo(0.5, 0.001));
    });

    test('a range spanning the whole file cuts nothing', () {
      final whole = slicePeaks(
        peaks,
        const AudioTrim(startMs: 0, endMs: 1000),
        1000,
      );

      expect(whole.length, 100);
    });
  });
}
