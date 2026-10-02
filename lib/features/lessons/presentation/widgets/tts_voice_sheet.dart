import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'tts_accent_field.dart';
import 'tts_quota_hint.dart';
import 'tts_voice_row.dart';
import 'tts_voice_sheet_wm.dart';

/// Voice-over settings sheet: a voice with a listen button, the accent and
/// the quota. The choice is saved as it is made.
class TtsVoiceSheet extends ElementaryWidget<TtsVoiceSheetWidgetModel> {
  const TtsVoiceSheet({super.key}) : super(ttsVoiceSheetWidgetModelFactory);

  @override
  Widget build(TtsVoiceSheetWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        wm.voices,
        wm.selection,
        wm.preview,
        wm.accents,
        wm.quotaLeft,
      ]),
      builder: (context, _) {
        final selection = wm.selection.value;
        final preview = wm.preview.value;
        final accents = wm.accents.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            switch (wm.voices.value) {
              // No choice from the provider — synthesis still works.
              AsyncReady(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(AppSpacing.s3),
                child: Text(
                  'The provider offers no voice choice — the voiceover will use the default '
                  'voice',
                  style: AppText.caption.copyWith(color: context.colors.text3),
                ),
              ),
              // Dozens of voices: the list scrolls, the controls below stay.
              AsyncReady(:final value) => Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: value.items.length,
                  itemBuilder: (context, index) {
                    final voice = value.items[index];
                    return TtsVoiceRow(
                      name: voice.name,
                      description: voice.description,
                      selected:
                          voice.name == (selection.voice ?? value.defaultVoice),
                      isLoading: preview.loadingVoice == voice.name,
                      isPlaying: preview.playingVoice == voice.name,
                      onSelect: () => wm.selectVoice(voice.name),
                      onPlay: () => wm.playSample(voice.name),
                    );
                  },
                ),
              ),
              AsyncFailed() => Padding(
                padding: const EdgeInsets.all(AppSpacing.s3),
                child: Text(
                  'The voice list failed to load — the voiceover will use the default '
                  'voice',
                  style: AppText.caption.copyWith(color: context.colors.text3),
                ),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(AppSpacing.s6),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            },
            if (preview.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                child: Text(
                  '«${preview.text}»',
                  style: AppText.caption.copyWith(color: context.colors.text3),
                ),
              ),
            if (accents.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              TtsAccentField(
                accents: accents,
                selected: selection.accent,
                onChanged: wm.selectAccent,
              ),
            ],
            TtsQuotaHint(remaining: wm.quotaLeft.value),
            const SizedBox(height: AppSpacing.s5),
            AppButton(label: 'Done', onPressed: wm.close),
          ],
        );
      },
    );
  }
}
