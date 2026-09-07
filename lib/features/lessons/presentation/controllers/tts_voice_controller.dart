import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Voice and accent of the voice-over, picked in settings and persisted.
class TtsVoiceController extends AsyncNotifier<TtsVoiceSelection> {
  static const String _voiceKey = 'tts_voice';
  static const String _accentKey = 'tts_accent';

  @override
  Future<TtsVoiceSelection> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return TtsVoiceSelection(
        voice: prefs.getString(_voiceKey),
        accent: prefs.getString(_accentKey),
      );
    } on Exception {
      // On a read error the server picks the voice itself.
      return const TtsVoiceSelection();
    }
  }

  TtsVoiceSelection get selection => state.value ?? const TtsVoiceSelection();

  Future<void> selectVoice(String voice) => _update(
    selection.copyWith(voice: voice),
    (prefs) => prefs.setString(_voiceKey, voice),
  );

  Future<void> selectAccent(String accent) => _update(
    selection.copyWith(accent: accent),
    (prefs) => prefs.setString(_accentKey, accent),
  );

  /// Accent for the request: the chosen one while it belongs to the current
  /// language, otherwise none.
  String? accentForRequest() {
    final accents = ref.read(currentAccentsProvider);
    if (accents.isEmpty) return null;
    final selected = selection.accent;
    return accents.any((accent) => accent.code == selected) ? selected : null;
  }

  /// Applies the choice immediately and stores it on disk.
  Future<void> _update(
    TtsVoiceSelection next,
    Future<void> Function(SharedPreferences) write,
  ) async {
    state = AsyncValue.data(next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await write(prefs);
    } on Exception {
      // The choice is applied; the write will not survive a restart.
    }
  }
}

final ttsVoiceControllerProvider =
    AsyncNotifierProvider<TtsVoiceController, TtsVoiceSelection>(
      TtsVoiceController.new,
    );

/// Chosen voice for the settings row; without one the server picks it.
final ttsVoiceLabelProvider = Provider<String>((ref) {
  final voice = ref.watch(ttsVoiceControllerProvider).value?.voice;
  return voice == null || voice.isEmpty ? 'По умолчанию' : voice;
});

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
