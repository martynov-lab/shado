// Windows pipeline check: flutter_soloud for peaks, media_kit for playback
// and sqflite ffi for the lesson cache.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:shado/core/platform/platform_setup.dart';
import 'package:shado/features/lessons/data/datasources/lesson_local_datasource_sqflite.dart';
import 'package:shado/features/lessons/data/datasources/waveform_datasource.dart';
import 'package:shado/features/lessons/data/datasources/waveform_datasource_soloud.dart';
import 'package:shado/features/lessons/data/models/lesson_model.dart';
import 'package:shado/features/lessons/data/models/segment_model.dart';
import 'package:shado/features/lessons/domain/entities/audio_trim.dart';

/// A two-second 440 Hz sine, 44100 Hz, mono, 16-bit.
File _writeTestWav(String path) {
  const sampleRate = 44100;
  const seconds = 2;
  const frames = sampleRate * seconds;
  final data = ByteData(44 + frames * 2);
  void ascii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + frames * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, frames * 2, Endian.little);
  for (var i = 0; i < frames; i++) {
    // The second second is quieter and the waveform must show it.
    final gain = i < frames ~/ 2 ? 0.9 : 0.2;
    final value = math.sin(2 * math.pi * 440 * i / sampleRate) * gain * 32767;
    data.setInt16(44 + i * 2, value.round(), Endian.little);
  }
  return File(path)..writeAsBytesSync(data.buffer.asUint8List());
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpPlatform();

  late Directory tempDir;
  late String wavPath;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('shado_pipeline');
    wavPath = p.join(tempDir.path, 'tone.wav');
    _writeTestWav(wavPath);
  });

  tearDownAll(() => tempDir.deleteSync(recursive: true));

  /// A request to the fallback local source, which works off the file.
  WaveformQuery query({int resolution = 200, AudioTrim? range}) =>
      WaveformQuery(
        audioId: 'local',
        localPath: wavPath,
        durationMs: 2000,
        resolution: resolution,
        range: range,
      );

  test('пики читаются и отражают перепад громкости', () async {
    const source = SoLoudWaveformDataSource();
    final peaks = await source.loadPeaks(query());
    expect(peaks.length, 200);
    expect(peaks.maxima.every((v) => v >= 0 && v <= 1), isTrue);
    expect(peaks.minima.every((v) => v <= 0 && v >= -1), isTrue);

    final loud = peaks.maxima.take(80).reduce(math.max);
    final quiet = peaks.maxima.skip(120).take(60).reduce(math.max);
    expect(loud, greaterThan(quiet * 2));

    // The second call must come from the cache and match.
    expect(File('$wavPath.peaks').existsSync(), isTrue);
    final cached = await source.loadPeaks(query());
    expect(cached.maxima, peaks.maxima);
  });

  test('пики отрезка считаются по нему, а не по файлу целиком', () async {
    const source = SoLoudWaveformDataSource();
    // Each half must keep the full resolution of 200 samples.
    final loud = await source.loadPeaks(
      query(range: const AudioTrim(startMs: 0, endMs: 1000)),
    );
    final quiet = await source.loadPeaks(
      query(range: const AudioTrim(startMs: 1000, endMs: 2000)),
    );

    expect(loud.length, 200);
    expect(quiet.length, 200);
    // A half is normalized on its own, so we check flatness, not loudness.
    for (final peaks in [loud, quiet]) {
      final head = peaks.maxima.take(80).reduce(math.max);
      final tail = peaks.maxima.skip(120).take(60).reduce(math.max);
      expect(tail, closeTo(head, head * 0.25));
    }

    // A range does not replace the cache: the file keeps its full waveform.
    final whole = await source.loadPeaks(query());
    final wholeHead = whole.maxima.take(80).reduce(math.max);
    final wholeTail = whole.maxima.skip(120).take(60).reduce(math.max);
    expect(wholeHead, greaterThan(wholeTail * 2));
  });

  // Only playback itself is checked here; boundaries live in
  // `lesson_playback_test.dart`.
  test('файл открывается, играет и доигрывает до конца', () async {
    final player = AudioPlayer();
    addTearDown(player.dispose);
    await player.setAudioSource(AudioSource.file(wavPath));
    await player.setLoopMode(LoopMode.off);
    await player.setSpeed(0.75);
    await player.seek(const Duration(milliseconds: 200));
    unawaited(player.play());
    await player.playerStateStream
        .firstWhere((s) => s.processingState == ProcessingState.completed)
        .timeout(const Duration(seconds: 10));
    expect(player.processingState, ProcessingState.completed);
  });

  test('урок пишется и читается из sqflite', () async {
    final db = SqfliteLessonLocalDataSource(
      databaseName: 'pipeline_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final lesson = LessonModel(
      id: 'test-lesson',
      title: 'Проверка',
      audioId: 'test-audio',
      audioPath: wavPath,
      durationMs: 2000,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      version: 1,
      segments: const [
        SegmentModel(index: 0, text: 'Hello', startMs: 0, endMs: 1000),
        SegmentModel(index: 1, text: 'World', startMs: 1000, endMs: 2000),
      ],
    );
    await db.upsertLesson(lesson);
    final loaded = await db.getLesson('test-lesson');
    expect(loaded?.title, 'Проверка');
    expect(loaded?.segments.length, 2);
    await db.deleteLesson('test-lesson');
    expect(await db.getLesson('test-lesson'), isNull);
  });
}
