// Playback boundaries on a live player: a loop restarts at the range start
// and a segment without a loop stops at its own boundary.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:shado/core/platform/platform_setup.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/di/settings_providers.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/segment.dart';
import 'package:shado/features/lessons/domain/entities/segment_range.dart';
import 'package:shado/features/lessons/domain/entities/tts_quota.dart';
import 'package:shado/features/lessons/domain/entities/tts_voice.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shado/features/lessons/presentation/screens/lesson/lesson_playback.dart';
import 'package:shado/features/lessons/presentation/screens/lesson/lesson_state.dart';
import 'package:shado/features/settings/domain/entities/playback_settings.dart';
import 'package:shado/features/settings/domain/repositories/playback_settings_repository.dart';

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
  Future<void> syncLessons({String language = ''}) async {}

  @override
  Future<Set<String>> downloadedLessonIds() async => const {};

  @override
  Future<void> downloadLesson(
    String id, {
    void Function(int received, int total)? onProgress,
  }) => Future.value();

  @override
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> removeDownload(String id) async {}

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
    String? voice,
    String? accent,
    Object? cancel,
  }) async => throw UnimplementedError();

  @override
  Future<TtsVoices> ttsVoices() async => throw UnimplementedError();

  @override
  Future<TtsPreview> previewTtsVoice({
    required String voice,
    String? accent,
  }) async => throw UnimplementedError();

  @override
  Future<TtsQuota> ttsQuota() async => throw UnimplementedError();

  @override
  Future<Lesson> createLesson({
    required String title,
    required String audioId,
    required int durationMs,
    required List<String> segmentTexts,
    required String? accent,
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
class _FixedPlaybackSettings implements PlaybackSettingsRepository {
  @override
  Future<PlaybackSettings> load() async => const PlaybackSettings(
    repeatsInCycle: 1000,
    pauseBetweenRepeats: false,
    countdownEnabled: false,
  );

  @override
  Future<void> save(PlaybackSettings settings) async {}
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
    title: 'Boundary check',
    audioPath: wavPath,
    durationMs: 4000,
    createdAt: DateTime.utc(2026),
    segments: const [
      Segment(index: 0, text: 'one', startMs: 0, endMs: 1000),
      Segment(index: 1, text: 'two', startMs: 1000, endMs: 2000),
      Segment(index: 2, text: 'three', startMs: 2000, endMs: 3000),
      Segment(index: 3, text: 'four', startMs: 3000, endMs: 4000),
    ],
  );

  /// The lesson opened on a live player; `state` keeps the latest screen state.
  Future<
    ({
      LessonPlayback playback,
      AudioPlayer player,
      ValueNotifier<LessonState?> state,
    })
  >
  openLesson(ProviderContainer container) async {
    final player = AudioPlayer();
    final state = ValueNotifier<LessonState?>(null);
    final playback = LessonPlayback(
      lessonId: lessonId,
      player: player,
      reporter: container.read(progressReporterProvider),
      settings: container.read(playbackSettingsServiceProvider),
      threshold: container.read(completionThresholdServiceProvider),
      onChanged: (value) => state.value = value,
      onPosition: (_) {},
    );
    addTearDown(playback.dispose);
    await playback.open(await container.read(getLessonProvider)(lessonId));
    return (playback: playback, player: player, state: state);
  }

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        lessonRepositoryProvider.overrideWithValue(
          _OneLessonRepository(buildLesson()),
        ),
        playbackSettingsRepositoryProvider.overrideWithValue(
          _FixedPlaybackSettings(),
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
    'a looped selection cycles inside itself, not from the start of the file',
    () async {
      final container = buildContainer();
      final lesson = await openLesson(container);
      final controller = lesson.playback;

      // The very case: the second and third segments (1000..3000 ms).
      controller.toggleSelection(1);
      controller.toggleSelection(2);
      expect(lesson.state.value?.selection, const SegmentRange(1, 2));

      // The loaded range loops as a single fragment.
      controller.toggleLoop();
      controller.finishSelecting();
      await controller.togglePlayCurrent();
      final player = lesson.player;

      // Two 2000 ms loops with room for the start-up.
      final trace = await tracePositions(player, 5200);
      await controller.togglePlayCurrent();

      // Drop the start-up: before the first seek the position is still zero.
      final started = trace.indexWhere((ms) => ms >= 1000);
      expect(started, isNonNegative, reason: 'the selection never started playing');
      final playing = trace.skip(started).toList();

      expect(
        playing.reduce(math.min),
        greaterThanOrEqualTo(1000 - toleranceMs),
        reason: 'a new lap ran off to the start of the file: $playing',
      );
      expect(
        playing.reduce(math.max),
        lessThanOrEqualTo(3000 + toleranceMs),
        reason: 'the selection ran into the fourth segment: $playing',
      );

      // A 2000 ms loop: five seconds must fit at least two of them.
      var wraps = 0;
      for (var i = 1; i < playing.length; i++) {
        if (playing[i] < playing[i - 1] - toleranceMs) wraps++;
      }
      expect(wraps, greaterThanOrEqualTo(2), reason: 'laps: $playing');
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'a segment without a loop plays itself out and rewinds to its own start',
    () async {
      final container = buildContainer();
      final lesson = await openLesson(container);
      final controller = lesson.playback;
      final player = lesson.player;

      // The second segment: 1000..2000 ms.
      await controller.togglePlay(1);
      final trace = await tracePositions(player, 2500);

      expect(
        trace.reduce(math.max),
        greaterThanOrEqualTo(2000 - toleranceMs),
        reason: 'the end of the segment was cut off: $trace',
      );
      expect(
        trace.reduce(math.max),
        lessThanOrEqualTo(2000 + toleranceMs),
        reason: 'the segment ran into the next one: $trace',
      );
      expect(lesson.state.value?.isPlaying, isFalse);
      expect(player.position.inMilliseconds, closeTo(1000, toleranceMs));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    '"Next segment" plays the new segment at once without finishing the old one',
    () async {
      final container = buildContainer();
      final lesson = await openLesson(container);
      final controller = lesson.playback;
      final player = lesson.player;

      // Play the first segment (0..1000) and let it run for a bit.
      await controller.togglePlay(0);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // The second segment plays at once without waiting for the first.
      await controller.next();
      final trace = await tracePositions(player, 1500);

      expect(
        trace.reduce(math.min),
        greaterThanOrEqualTo(1000 - toleranceMs),
        reason: 'after "Next" the player fell back into the previous segment: $trace',
      );
      expect(
        trace.reduce(math.max),
        greaterThanOrEqualTo(2000 - toleranceMs),
        reason: 'the second segment never started playing: $trace',
      );
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
