import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Playback controls under the card.
class PhraseSetTransport extends StatelessWidget {
  const PhraseSetTransport({
    super.key,
    required this.isPlaying,
    required this.isRepeating,
    required this.isLooping,
    required this.canLoop,
    required this.speedLabel,
    required this.onToggleRepeat,
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
    required this.onToggleLoop,
    required this.onPickSpeed,
  });

  final bool isPlaying;

  /// The current phrase repeats.
  final bool isRepeating;

  /// The deck plays round and round.
  final bool isLooping;

  /// Whether the deck loop is available (Listen only).
  final bool canLoop;

  final String speedLabel;
  final VoidCallback onToggleRepeat;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onToggleLoop;
  final VoidCallback onPickSpeed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIconButton(
          icon: Icons.repeat_one_rounded,
          semanticLabel: isRepeating ? 'Stop repeating' : 'Repeat phrase',
          variant: isRepeating
              ? AppButtonVariant.secondary
              : AppButtonVariant.ghost,
          onPressed: onToggleRepeat,
        ),
        const SizedBox(width: AppSpacing.s1),
        AppIconButton(
          icon: Icons.skip_previous_rounded,
          semanticLabel: 'Previous phrase',
          onPressed: onPrevious,
        ),
        const SizedBox(width: AppSpacing.s1),
        AppIconButton(
          icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          semanticLabel: isPlaying ? 'Pause' : 'Play',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.lg,
          onPressed: onTogglePlay,
        ),
        const SizedBox(width: AppSpacing.s1),
        AppIconButton(
          icon: Icons.skip_next_rounded,
          semanticLabel: 'Next phrase',
          onPressed: onNext,
        ),
        const SizedBox(width: AppSpacing.s1),
        AppIconButton(
          icon: Icons.repeat_rounded,
          semanticLabel: isLooping ? 'Stop the loop' : 'Loop the deck',
          variant: isLooping
              ? AppButtonVariant.secondary
              : AppButtonVariant.ghost,
          onPressed: canLoop ? onToggleLoop : null,
        ),
        const SizedBox(width: AppSpacing.s1),
        AppButton(
          label: speedLabel,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          onPressed: onPickSpeed,
        ),
      ],
    );
  }
}
