import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/lesson_providers.dart';

import '../../../languages/domain/entities/language.dart';
import '../../../languages/domain/services/language_service.dart';
import '../../domain/entities/tts_quota.dart';
import '../../domain/entities/tts_voice.dart';
import '../../domain/entities/tts_voice_selection.dart';
import '../../domain/services/tts_voice_service.dart';
import '../../domain/usecases/get_tts_quota.dart';
import '../../domain/usecases/get_tts_voices.dart';
import '../../domain/usecases/preview_tts_voice.dart';

/// Voices, the quota and voice samples for the voice-over sheet. Samples play
/// on a player of their own.
class TtsVoiceSheetModel extends ElementaryModel {
  TtsVoiceSheetModel(ProviderContainer container)
    : _voices = container.read(ttsVoiceServiceProvider),
      _languages = container.read(languageServiceProvider),
      _getVoices = container.read(getTtsVoicesProvider),
      _getQuota = container.read(getTtsQuotaProvider),
      _previewVoice = container.read(previewTtsVoiceProvider);

  final TtsVoiceService _voices;
  final LanguageService _languages;
  final GetTtsVoices _getVoices;
  final GetTtsQuota _getQuota;
  final PreviewTtsVoice _previewVoice;
  final AudioPlayer _player = AudioPlayer();

  late final StreamValueNotifier<TtsVoiceSelection> _selection =
      StreamValueNotifier(_voices.selection, _voices.changes);
  late final StreamValueNotifier<List<Accent>> _accents = StreamValueNotifier(
    _languages.currentAccents,
    _languages.currentChanges.map((language) => language?.accents ?? const []),
  );

  ValueListenable<TtsVoiceSelection> get selection => _selection;

  /// Accents of the studied language; empty hides the accent picker.
  ValueListenable<List<Accent>> get accents => _accents;

  /// Fires when a sample finishes or is stopped.
  Stream<void> get sampleStopped => _player.playerStateStream.where(
    (state) =>
        state.processingState == ProcessingState.completed || !state.playing,
  );

  @override
  void init() {
    super.init();
    _voices.load().ignore();
  }

  Future<TtsVoices> loadVoices() => _getVoices();

  Future<TtsQuota> loadQuota() => _getQuota();

  Future<void> selectVoice(String voice) => _voices.selectVoice(voice);

  Future<void> selectAccent(String accent) => _voices.selectAccent(accent);

  /// Plays a sample of [voice] and returns its phrase. A repeat costs no
  /// quota: the sample is cached.
  Future<String> playSample(String voice) async {
    final preview = await _previewVoice(
      voice: voice,
      accent: _voices.accentForRequest(),
    );
    await _player.setFilePath(preview.localPath);
    // play() completes only at the end of the sample — do not await it.
    _player.play().ignore();
    return preview.text;
  }

  Future<void> stopSample() => _player.stop();

  @override
  void dispose() {
    _player.dispose();
    _selection.dispose();
    _accents.dispose();
    super.dispose();
  }
}
