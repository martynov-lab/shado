import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../screens/phrase_set/phrase_study_mode.dart';

/// Study controls above the card: the mode, shuffle and deck selection.
class PhraseSetToolbar extends StatelessWidget {
  const PhraseSetToolbar({
    super.key,
    required this.mode,
    required this.isShuffled,
    required this.deckLabel,
    required this.onModeChanged,
    required this.onToggleShuffle,
    required this.onSelect,
    required this.onResetDeck,
  });

  final PhraseStudyMode mode;
  final bool isShuffled;

  /// `3 / 8 selected` while the deck is a part of the set; `null` otherwise.
  final String? deckLabel;

  final ValueChanged<PhraseStudyMode> onModeChanged;
  final VoidCallback onToggleShuffle;
  final VoidCallback onSelect;
  final VoidCallback onResetDeck;

  @override
  Widget build(BuildContext context) {
    final deckLabel = this.deckLabel;

    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      children: [
        AppSegmentedControl<PhraseStudyMode>(
          value: mode,
          segments: [
            for (final value in PhraseStudyMode.values)
              AppSegment(value: value, label: value.label),
          ],
          onChanged: onModeChanged,
          semanticLabel: 'Study mode',
        ),
        AppIconButton(
          icon: Icons.shuffle_rounded,
          semanticLabel: isShuffled ? 'Original order' : 'Shuffle',
          variant: isShuffled
              ? AppButtonVariant.secondary
              : AppButtonVariant.ghost,
          onPressed: onToggleShuffle,
        ),
        AppButton(
          label: 'Select',
          icon: Icons.checklist_rounded,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          onPressed: onSelect,
        ),
        if (deckLabel != null)
          AppButton(
            label: '$deckLabel · Show all',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.sm,
            onPressed: onResetDeck,
          ),
      ],
    );
  }
}
