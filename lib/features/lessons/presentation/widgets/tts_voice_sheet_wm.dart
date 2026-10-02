import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../languages/domain/entities/language.dart';
import '../../domain/entities/tts_voice.dart';
import '../../domain/entities/tts_voice_selection.dart';
import 'tts_preview_state.dart';
import 'tts_voice_sheet.dart';
import 'tts_voice_sheet_model.dart';

TtsVoiceSheetWidgetModel ttsVoiceSheetWidgetModelFactory(
  BuildContext context,
) => TtsVoiceSheetWidgetModel(
  TtsVoiceSheetModel(ProviderScope.containerOf(context, listen: false)),
);

class TtsVoiceSheetWidgetModel
    extends WidgetModel<TtsVoiceSheet, TtsVoiceSheetModel> {
  TtsVoiceSheetWidgetModel(super.model);

  final ValueNotifier<AsyncState<TtsVoices>> _voices = ValueNotifier(
    const AsyncPending(),
  );
  final ValueNotifier<int?> _quotaLeft = ValueNotifier(null);
  final ValueNotifier<TtsPreviewState> _preview = ValueNotifier(
    const TtsPreviewState(),
  );
  StreamSubscription<void>? _sampleSubscription;

  ValueListenable<AsyncState<TtsVoices>> get voices => _voices;
  ValueListenable<TtsVoiceSelection> get selection => model.selection;
  ValueListenable<List<Accent>> get accents => model.accents;
  ValueListenable<TtsPreviewState> get preview => _preview;

  /// Voice-overs left today; `null` hides the hint (unlimited or unknown).
  ValueListenable<int?> get quotaLeft => _quotaLeft;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _sampleSubscription = model.sampleStopped.listen((_) {
      if (_preview.value.playingVoice != null) {
        _preview.value = TtsPreviewState(text: _preview.value.text);
      }
    });
    unawaited(_loadVoices());
    unawaited(_loadQuota());
  }

  @override
  void dispose() {
    _sampleSubscription?.cancel();
    _voices.dispose();
    _quotaLeft.dispose();
    _preview.dispose();
    super.dispose();
  }

  void selectVoice(String voice) => unawaited(model.selectVoice(voice));

  void selectAccent(String accent) => unawaited(model.selectAccent(accent));

  /// Plays the sample of [voice]; a second tap on the playing one stops it.
  Future<void> playSample(String voice) async {
    final context = this.context;
    final current = _preview.value;
    if (current.loadingVoice != null) return;
    if (current.playingVoice == voice) {
      await model.stopSample();
      _preview.value = TtsPreviewState(text: current.text);
      return;
    }
    _preview.value = TtsPreviewState(loadingVoice: voice, text: current.text);
    try {
      final text = await model.playSample(voice);
      if (isMounted) {
        _preview.value = TtsPreviewState(playingVoice: voice, text: text);
      }
    } catch (error) {
      if (!context.mounted) return;
      _preview.value = TtsPreviewState(text: current.text);
      showAppSnackbar(
        context,
        message: 'Failed to play the voice: $error',
        variant: AppSnackbarVariant.warning,
      );
    }
  }

  void close() => Navigator.of(context).pop();

  Future<void> _loadVoices() async {
    final voices = await AsyncState.guard(model.loadVoices);
    if (isMounted) _voices.value = voices;
  }

  Future<void> _loadQuota() async {
    try {
      final day = (await model.loadQuota()).day;
      if (!isMounted || day.isUnlimited) return;
      _quotaLeft.value = day.remaining;
    } catch (_) {
      return;
    }
  }
}
