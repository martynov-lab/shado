import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../languages/presentation/controllers/language_providers.dart';
import '../../domain/entities/tts_voice.dart';
import '../controllers/lesson_providers.dart';
import '../controllers/tts_voice_controller.dart';
import 'tts_accent_field.dart';
import 'tts_quota_hint.dart';
import 'tts_voice_row.dart';

/// Voice-over sheet: a voice with a listen button, the accent and the quota.
/// Popping `true` starts the synthesis.
class TtsVoiceSheet extends ConsumerWidget {
  const TtsVoiceSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voices = ref.watch(ttsVoicesProvider);
    final selection = ref.watch(ttsVoiceControllerProvider);
    final preview = ref.watch(ttsPreviewControllerProvider);
    final hasAccents = ref.watch(currentAccentsProvider).isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (voices) {
          // No choice from the provider — synthesis still works.
          AsyncData(:final value) when value.isEmpty => const SizedBox.shrink(),
          AsyncData(:final value) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final TtsVoice voice in value.items)
                TtsVoiceRow(
                  name: voice.name,
                  description: voice.description,
                  selected:
                      voice.name == (selection.voice ?? value.defaultVoice),
                  isLoading: preview.loadingVoice == voice.name,
                  isPlaying: preview.playingVoice == voice.name,
                  onSelect: () => ref
                      .read(ttsVoiceControllerProvider.notifier)
                      .selectVoice(voice.name),
                  onPlay: () => _play(context, ref, voice.name),
                ),
            ],
          ),
          AsyncError() => Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Text(
              'Список голосов не загрузился — озвучка пойдёт голосом по '
              'умолчанию',
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
        if (hasAccents) ...[
          const SizedBox(height: AppSpacing.s4),
          const TtsAccentField(),
        ],
        const TtsQuotaHint(),
        const SizedBox(height: AppSpacing.s5),
        AppButton(
          label: 'Озвучить',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  /// Plays a sample; a repeat costs no quota, so the button stays enabled.
  Future<void> _play(BuildContext context, WidgetRef ref, String voice) async {
    try {
      await ref.read(ttsPreviewControllerProvider.notifier).play(voice);
    } catch (error) {
      if (!context.mounted) return;
      showAppSnackbar(
        context,
        message: 'Не удалось прослушать голос: $error',
        variant: AppSnackbarVariant.warning,
      );
    }
  }
}
