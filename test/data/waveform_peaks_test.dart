import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/datasources/waveform_datasource.dart';
import 'package:shado/features/lessons/data/models/waveform_peaks.dart';
import 'package:shado/features/lessons/domain/entities/audio_trim.dart';

/// Кодирует значения так же, как сервер: int8 в base64.
String encode(List<int> values) =>
    base64Encode(Int8List.fromList(values).buffer.asUint8List());

void main() {
  group('decodePeaks', () {
    test('разбирает base64 int8 в доли единицы', () {
      final decoded = decodePeaks(encode([127, 64, 0, -64, -127]));

      expect(decoded, hasLength(5));
      expect(decoded.first, closeTo(1.0, 0.001));
      expect(decoded[1], closeTo(0.504, 0.001));
      expect(decoded[2], 0.0);
      expect(decoded.last, closeTo(-1.0, 0.001));
    });

    test('держится в диапазоне -1..1 на всех значениях int8', () {
      final decoded = decodePeaks(encode([for (var i = -128; i < 128; i++) i]));

      expect(decoded, hasLength(256));
      // -128/127 чуть выходит за -1: это край типа, а не ошибка кодирования.
      expect(decoded.every((value) => value >= -1.008 && value <= 1.0), isTrue);
    });

    test('пустая строка — пустая волна', () {
      expect(decodePeaks(''), isEmpty);
    });

    test('длина совпадает с числом точек, присланных сервером', () {
      final peaks = WaveformPeaks.fromJson({
        'resolution': 3,
        'minima': encode([-127, -64, -10]),
        'maxima': encode([127, 64, 10]),
      });

      expect(peaks.length, 3);
      expect(peaks.maxima.every((value) => value >= 0), isTrue);
      expect(peaks.minima.every((value) => value <= 0), isTrue);
    });

    test('фактическое разрешение берётся из массивов, а не из поля', () {
      // Сервер не может отдать больше точек, чем сохранил: просили 2000,
      // прислал 2 — рисовать надо по тому, что пришло.
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

    test('без отрезка отдаёт волну как есть', () {
      expect(slicePeaks(peaks, null, 1000).length, 100);
    });

    test('вырезает долю, соответствующую отрезку', () {
      final half = slicePeaks(
        peaks,
        const AudioTrim(startMs: 500, endMs: 1000),
        1000,
      );

      expect(half.length, 50);
      // Вторая половина файла — её и должны получить.
      expect(half.maxima.first, closeTo(0.5, 0.001));
    });

    test('отрезок во весь файл ничего не режет', () {
      final whole = slicePeaks(
        peaks,
        const AudioTrim(startMs: 0, endMs: 1000),
        1000,
      );

      expect(whole.length, 100);
    });
  });
}
