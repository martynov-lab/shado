import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/audio/clip_player.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_kind.dart';
import 'package:shado/features/lessons/domain/entities/phrase.dart';
import 'package:shado/features/lessons/presentation/screens/phrase_set/phrase_set_playback.dart';
import 'package:shado/features/lessons/presentation/screens/phrase_set/phrase_set_state.dart';
import 'package:shado/features/lessons/presentation/screens/phrase_set/phrase_study_mode.dart';
import 'package:shado/features/progress/domain/services/progress_reporter.dart';
import 'package:shado/features/progress/domain/services/progress_summary_service.dart';
import 'package:shado/features/settings/data/repositories/playback_settings_repository_impl.dart';
import 'package:shado/features/settings/domain/services/playback_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/fake_progress_repository.dart';

/// A player that records what it was asked to play; the test ends clips.
class _FakeClipPlayer implements ClipPlayer {
  final List<({String path, int startMs, int? endMs})> played = [];
  final StreamController<void> _completions = StreamController.broadcast();
  final StreamController<bool> _playing = StreamController.broadcast();
  bool _isPlaying = false;

  void complete() {
    _isPlaying = false;
    _completions.add(null);
  }

  @override
  Stream<void> get completions => _completions.stream;

  @override
  Stream<bool> get playingChanges => _playing.stream;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> play(String path, {int startMs = 0, int? endMs}) async {
    played.add((path: path, startMs: startMs, endMs: endMs));
    _isPlaying = true;
  }

  @override
  Future<void> stop() async => _isPlaying = false;

  @override
  // The fake does nothing here.
  // ignore: no-empty-block
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {
    await _completions.close();
    await _playing.close();
  }
}

Lesson _set(int count) => Lesson(
  id: 'set-1',
  title: 'Set',
  audioPath: '',
  durationMs: 0,
  createdAt: DateTime.utc(2026, 11, 2),
  segments: const [],
  kind: LessonKind.expressions,
  phrases: [
    for (var i = 0; i < count; i++)
      Phrase(
        id: 'p$i',
        text: 'Phrase $i',
        audioId: 'a$i',
        audioPath: '/cache/a$i.wav',
        durationMs: 1000,
      ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeClipPlayer player;
  late FakeProgressRepository progress;
  late PhraseSetPlayback playback;
  late PhraseSetState state;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    player = _FakeClipPlayer();
    progress = FakeProgressRepository();
    final summary = ProgressSummaryService(progress);
    final settings = PlaybackSettingsService(PlaybackSettingsRepositoryImpl());
    await settings.load();
    await settings.setPauseBetweenRepeats(false);
    playback = PhraseSetPlayback(
      lessonId: 'set-1',
      player: player,
      reporter: ProgressReporter(repository: progress, summary: summary),
      settings: settings,
      random: Random(3),
      onChanged: (value) => state = value,
    );
    await playback.open(_set(5));
    addTearDown(() async {
      await playback.dispose();
      summary.dispose();
      settings.dispose();
    });
  });

  test('opens on the first phrase with the whole set as the deck', () {
    expect(state.deck, [0, 1, 2, 3, 4]);
    expect(state.phraseIndex, 0);
    expect(state.isPartialDeck, isFalse);
  });

  test('stepping wraps around the deck', () async {
    await playback.step(-1);

    expect(state.phraseIndex, 4);
  });

  test('shuffle keeps the card on screen and switching it off restores the order', () async {
    await playback.step(2);

    playback.toggleShuffle();
    expect(state.isShuffled, isTrue);
    expect(state.order.toSet(), {0, 1, 2, 3, 4});
    expect(state.phraseIndex, 2);

    playback.toggleShuffle();
    expect(state.order, [0, 1, 2, 3, 4]);
    expect(state.phraseIndex, 2);
  });

  test('applying a selection makes it the deck', () async {
    playback
      ..startSelecting()
      ..toggleSelected(3)
      ..toggleSelected(1);

    await playback.applySelection();

    expect(state.deck, [1, 3]);
    expect(state.phraseIndex, 1);
    expect(state.isSelecting, isFalse);
    expect(state.isPartialDeck, isTrue);
  });

  test('an empty selection brings back the whole set', () async {
    playback.select([2]);
    await playback.applySelection();
    playback.startSelecting();
    playback.select(const []);

    await playback.applySelection();

    expect(state.deck, [0, 1, 2, 3, 4]);
  });

  test('a looped deck plays on to the next phrase', () async {
    playback.toggleLooping();
    await playback.togglePlay();

    player.complete();
    await pumpEventQueue();

    expect(player.played.map((p) => p.path), [
      '/cache/a0.wav',
      '/cache/a1.wav',
    ]);
    expect(state.phraseIndex, 1);
    expect(progress.segmentRepeats, 1);
  });

  test('a repeated phrase plays again instead of moving on', () async {
    playback
      ..toggleLooping()
      ..toggleRepeating();
    await playback.togglePlay();

    player.complete();
    await pumpEventQueue();

    expect(player.played.map((p) => p.path), [
      '/cache/a0.wav',
      '/cache/a0.wav',
    ]);
  });

  test('without a loop a finished phrase stops', () async {
    await playback.togglePlay();

    player.complete();
    await pumpEventQueue();

    expect(state.isPlaying, isFalse);
    expect(player.played, hasLength(1));
  });

  test('recall: a flip shows the phrase and plays it, the next card is face down', () async {
    await playback.setMode(PhraseStudyMode.recall);
    expect(state.showsPhrase, isFalse);

    await playback.flip();
    expect(state.showsPhrase, isTrue);
    expect(player.played.single.path, '/cache/a0.wav');

    await playback.step(1);
    expect(state.isFlipped, isFalse);
  });

  test('a phrase from a story plays only its range', () async {
    await playback.open(
      _set(1).copyWith(
        phrases: const [
          Phrase(
            id: 'p',
            text: 'Hi',
            audioId: 'story',
            audioPath: '/cache/story.mp3',
            durationMs: 500,
            startMs: 1000,
            endMs: 1500,
          ),
        ],
      ),
    );

    await playback.togglePlay();

    expect(player.played.single, (
      path: '/cache/story.mp3',
      startMs: 1000,
      endMs: 1500,
    ));
  });
}
