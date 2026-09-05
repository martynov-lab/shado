// Playback boundaries on a live player: a loop restarts at the range start
// and a segment without a loop stops at its own boundary.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:shado/core/platform/platform_setup.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';
import 'package:shado/features/lessons/domain/entities/segment_range.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shado/features/lessons/presentation/controllers/lesson_controller.dart';
import 'package:shado/features/lessons/presentation/controllers/lesson_providers.dart';
import 'package:shado/features/settings/domain/entities/playback_settings.dart';
import 'package:shado/features/settings/presentation/controllers/playback_settings_controller.dart';

/// A flat tone of [seconds] seconds; only the positions matter.
File _writeTestWav(String path, {int seconds = 4}) {
  const sampleRate = 44100;
  final frames = sampleRate * seconds;
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
    final value = math.sin(2 * math.pi * 440 * i / sampleRate) * 0.5 * 32767;
    data.setInt16(44 + i * 2, value.round(), Endian.little);
  }
  return File(path)..writeAsBytesSync(data.buffer.asUint8List());
}

/// Returns a single lesson; this test touches neither network nor cache.
class _OneLessonRepository implements LessonRepository {
  _OneLessonRepository(this.lesson);

  final Lesson lesson;

  @override
  Future<Lesson?> getLesson(String id) async => lesson;

  @override
  Future<List<Lesson>> getLessons() async => [lesson];

  @override
  Future<void> syncLessons() async {}

  @override
  Future<List<Topic>> getTopics() async => const [];

  @override
  Future<AudioUpload> uploadAudio({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    Object? cancel,
  }) async => throw UnimplementedError();

  @override
  Future<AudioUpload> synthesizeTts({
    required String text,
    Object? cancel,
  }) async => throw UnimplementedError();

  @override
  Future<TtsQuota> ttsQuota() async => throw UnimplementedError();

  @override
  Future<Lesson> createLesson({
    required String title,
    required String audioId,
    required int durationMs,
    required List<String> segmentTexts,
    required LessonAccent accent,
    required LessonLevel level,
    String? topicId,
    List<int>? boundaries,
    bool? isPublic,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateLesson(Lesson lesson, {bool? isPublic}) async {}

  @override
  Future<void> deleteLesson(String id) async {}

  @override
  Future<void> clearCache() async {}
}

/// Fixed settings: an endless loop with no pause and no countdown.
class _FixedPlaybackSettings extends PlaybackSettingsController {
  @override
  Future<PlaybackSettings> build() async => const PlaybackSettings(
    repeatsInCycle: 1000,
    pauseBetweenRepeats: false,
    countdownEnabled: false,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpPlatform();

  const lessonId = 'playback-test';

  /// How far the position may drift: the watcher tick plus seek accuracy.
  const toleranceMs = 80;

  late Directory tempDir;
  late String wavPath;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('shado_playback');
    wavPath = p.join(tempDir.path, 'tone.wav');
    _writeTestWav(wavPath);
  });

  tearDownAll(() => tempDir.deleteSync(recursive: true));

  /// A lesson of four one-second segments.
  Lesson buildLesson() => Lesson(
    id: lessonId,
    title: 'Проверка границ',
    audioPath: wavPath,
    durationMs: 4000,
    createdAt: DateTime.utc(2026),
    segments: const [
      Segment(index: 0, text: 'один', startMs: 0, endMs: 1000),
      Segment(index: 1, text: 'два', startMs: 1000, endMs: 2000),
      Segment(index: 2, text: 'три', startMs: 2000, endMs: 3000),
      Segment(index: 3, text: 'четыре', startMs: 3000, endMs: 4000),
    ],
  );

  /// A ready lesson controller with a live player.
  Future<LessonController> openLesson(ProviderContainer container) async {
    final provider = lessonControllerProvider(lessonId);
    // autoDispose: with no listener the controller and player close at once.
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    return container.read(provider.notifier);
  }

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        lessonRepositoryProvider.overrideWithValue(
          _OneLessonRepository(buildLesson()),
        ),
        playbackSettingsControllerProvider.overrideWith(
          _FixedPlaybackSettings.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// A stream of player positions over [ms] of real time.
  Future<List<int>> tracePositions(AudioPlayer player, int ms) async {
    final watch = Stopwatch()..start();
    final trace = <int>[];
    while (watch.elapsedMilliseconds < ms) {
      trace.add(player.position.inMilliseconds);
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    return trace;
  }

  test(
    'зацикленное выделение крутится внутри себя, а не с начала файла',
    () async {
      final container = buildContainer();
      final controller = await openLesson(container);
      final provider = lessonControllerProvider(lessonId);

      // The very case: the second and third segments (1000..3000 ms).
      controller.toggleSelection(1);
      controller.toggleSelection(2);
      expect(
        container.read(provider).value?.selection,
        const SegmentRange(1, 2),
      );

      // The loaded range loops as a single fragment.
      controller.toggleLoop();
      controller.finishSelecting();
      await controller.togglePlayCurrent();
      final player = container.read(lessonAudioPlayerProvider(lessonId));

      // Two 2000 ms loops with room for the start-up.
      final trace = await tracePositions(player, 5200);
      await controller.togglePlayCurrent();

      // Drop the start-up: before the first seek the position is still zero.
      final started = trace.indexWhere((ms) => ms >= 1000);
      expect(started, isNonNegative, reason: 'выделение так и не заиграло');
      final playing = trace.skip(started).toList();

      expect(
        playing.reduce(math.min),
        greaterThanOrEqualTo(1000 - toleranceMs),
        reason: 'новый круг уехал в начало файла: $playing',
      );
      expect(
        playing.reduce(math.max),
        lessThanOrEqualTo(3000 + toleranceMs),
        reason: 'выделение заехало в четвёртый кусок: $playing',
      );

      // A 2000 ms loop: five seconds must fit at least two of them.
      var wraps = 0;
      for (var i = 1; i < playing.length; i++) {
        if (playing[i] < playing[i - 1] - toleranceMs) wraps++;
      }
      expect(wraps, greaterThanOrEqualTo(2), reason: 'круги: $playing');
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'кусок без цикла доигрывает себя и встаёт на своё начало',
    () async {
      final container = buildContainer();
      final controller = await openLesson(container);
      final provider = lessonControllerProvider(lessonId);
      final player = container.read(lessonAudioPlayerProvider(lessonId));

      // The second segment: 1000..2000 ms.
      await controller.togglePlay(1);
      final trace = await tracePositions(player, 2500);

      expect(
        trace.reduce(math.max),
        greaterThanOrEqualTo(2000 - toleranceMs),
        reason: 'конец куска обрезан: $trace',
      );
      expect(
        trace.reduce(math.max),
        lessThanOrEqualTo(2000 + toleranceMs),
        reason: 'кусок заехал в следующий: $trace',
      );
      expect(container.read(provider).value?.isPlaying, isFalse);
      expect(player.position.inMilliseconds, closeTo(1000, toleranceMs));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    '«Следующий сегмент» сразу играет новый кусок, не доигрывая прежний',
    () async {
      final container = buildContainer();
      final controller = await openLesson(container);
      final player = container.read(lessonAudioPlayerProvider(lessonId));

      // Play the first segment (0..1000) and let it run for a bit.
      await controller.togglePlay(0);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // The second segment plays at once without waiting for the first.
      await controller.next();
      final trace = await tracePositions(player, 1500);

      expect(
        trace.reduce(math.min),
        greaterThanOrEqualTo(1000 - toleranceMs),
        reason: 'после «Следующий» плеер вернулся в прошлый кусок: $trace',
      );
      expect(
        trace.reduce(math.max),
        greaterThanOrEqualTo(2000 - toleranceMs),
        reason: 'второй кусок так и не заиграл: $trace',
      );
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
