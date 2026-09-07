import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../languages/presentation/controllers/language_providers.dart';
import 'lesson_providers.dart';

/// Voice and accent chosen for the AI voice-over.
class TtsVoiceSelection {
  const TtsVoiceSelection({this.voice, this.accent});

  /// `null` lets the server use its default voice.
  final String? voice;

  /// Voice-over accent; `null` for languages without accents.
  final String? accent;

  TtsVoiceSelection copyWith({String? voice, String? accent}) =>
      TtsVoiceSelection(
        voice: voice ?? this.voice,
        accent: accent ?? this.accent,
      );
}

/// Voice and accent of the voice-over; kept between openings of the sheet.
class TtsVoiceController extends Notifier<TtsVoiceSelection> {
  @override
  TtsVoiceSelection build() => const TtsVoiceSelection();

  void selectVoice(String voice) => state = state.copyWith(voice: voice);

  void selectAccent(String accent) => state = state.copyWith(accent: accent);

  /// Accent for the request: the chosen one while it belongs to the current
  /// language, otherwise none.
  String? accentForRequest() {
    final accents = ref.read(currentAccentsProvider);
    if (accents.isEmpty) return null;
    final selected = state.accent;
    return accents.any((accent) => accent.code == selected) ? selected : null;
  }
}

final ttsVoiceControllerProvider =
    NotifierProvider<TtsVoiceController, TtsVoiceSelection>(
      TtsVoiceController.new,
    );

/// Player of the voice samples; separate from the lesson players.
final ttsPreviewPlayerProvider = Provider.autoDispose<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// Which sample is being fetched or played and what the phrase is.
class TtsPreviewState {
  const TtsPreviewState({this.loadingVoice, this.playingVoice, this.text = ''});

  /// Voice whose sample is being fetched; `null` when nothing is loading.
  final String? loadingVoice;

  /// Voice being played right now.
  final String? playingVoice;

  /// Phrase of the last sample.
  final String text;
}

/// Listening to voice samples inside the voice-over sheet.
class TtsPreviewController extends Notifier<TtsPreviewState> {
  AudioPlayer get _player => ref.read(ttsPreviewPlayerProvider);

  @override
  TtsPreviewState build() {
    final player = ref.watch(ttsPreviewPlayerProvider);
    final subscription = player.playerStateStream.listen((playerState) {
      final finished =
          playerState.processingState == ProcessingState.completed ||
          !playerState.playing;
      if (finished && state.playingVoice != null) {
        state = TtsPreviewState(text: state.text);
      }
    });
    ref.onDispose(subscription.cancel);
    return const TtsPreviewState();
  }

  /// Plays the sample of [voice]; a repeat costs no quota — it is cached.
  Future<void> play(String voice) async {
    if (state.loadingVoice != null) return;
    if (state.playingVoice == voice) {
      await _player.stop();
      state = TtsPreviewState(text: state.text);
      return;
    }
    state = TtsPreviewState(loadingVoice: voice, text: state.text);
    try {
      final preview = await ref.read(previewTtsVoiceProvider)(
        voice: voice,
        accent: ref
            .read(ttsVoiceControllerProvider.notifier)
            .accentForRequest(),
      );
      await _player.setFilePath(preview.localPath);
      state = TtsPreviewState(playingVoice: voice, text: preview.text);
      // play() completes only at the end of the sample — do not await it.
      unawaited(_player.play());
    } catch (_) {
      state = TtsPreviewState(text: state.text);
      rethrow;
    }
  }
}

final ttsPreviewControllerProvider =
    NotifierProvider.autoDispose<TtsPreviewController, TtsPreviewState>(
      TtsPreviewController.new,
    );
