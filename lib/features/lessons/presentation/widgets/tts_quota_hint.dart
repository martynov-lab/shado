import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Caption with the voice-overs left today.
class TtsQuotaHint extends StatelessWidget {
  const TtsQuotaHint({super.key, required this.remaining});

  /// `null` hides the caption: no limit or the quota is unknown.
  final int? remaining;

  @override
  Widget build(BuildContext context) {
    final remaining = this.remaining;
    if (remaining == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s2),
      child: Text(
        'Voiceovers left today: $remaining',
        style: AppText.caption.copyWith(color: context.colors.text3),
      ),
    );
  }
}
