import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'tts_quota_hint.dart';

/// Bulk actions under the phrase list: translate the missing translations
/// and voice the phrases that need it.
class PhraseSetEditorActions extends StatelessWidget {
  const PhraseSetEditorActions({
    super.key,
    required this.toTranslate,
    required this.toVoice,
    required this.isTranslating,
    required this.isVoicing,
    required this.isBusy,
    required this.quotaLeft,
    required this.onTranslateAll,
    required this.onVoiceAll,
  });

  /// Phrases without a translation.
  final int toTranslate;

  /// Phrases without up-to-date audio.
  final int toVoice;

  final bool isTranslating;
  final bool isVoicing;
  final bool isBusy;

  /// Voice-overs left today; `null` hides the hint.
  final int? quotaLeft;

  final VoidCallback onTranslateAll;
  final VoidCallback onVoiceAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.s3,
          runSpacing: AppSpacing.s2,
          children: [
            AppButton(
              label: toTranslate > 0
                  ? 'Translate all ($toTranslate)'
                  : 'Translate all',
              icon: Icons.translate_rounded,
              variant: AppButtonVariant.secondary,
              loading: isTranslating,
              onPressed: toTranslate > 0 && !isBusy ? onTranslateAll : null,
            ),
            AppButton(
              label: toVoice > 0 ? 'Voice all ($toVoice)' : 'All voiced',
              icon: Icons.record_voice_over_outlined,
              loading: isVoicing,
              onPressed: toVoice > 0 && !isBusy ? onVoiceAll : null,
            ),
          ],
        ),
        TtsQuotaHint(remaining: quotaLeft),
      ],
    );
  }
}
