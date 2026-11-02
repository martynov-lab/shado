import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'phrase_select_row.dart';

/// The phrase list in a sheet: a tap opens a phrase, in selection mode it
/// builds the deck, with quick picks by rating.
class PhraseSelectPanel extends StatelessWidget {
  const PhraseSelectPanel({
    super.key,
    required this.texts,
    required this.stars,
    required this.currentIndex,
    required this.isSelecting,
    required this.selection,
    required this.onTap,
    required this.onPickAll,
    required this.onPickUnrated,
    required this.onPickWeak,
    required this.onClear,
    required this.onApply,
  });

  /// Phrase texts in lesson order.
  final List<String> texts;

  /// Rating of every phrase, in lesson order.
  final List<int> stars;

  final int currentIndex;
  final bool isSelecting;
  final Set<int> selection;

  /// Opens the phrase, or toggles it in selection mode.
  final ValueChanged<int> onTap;

  final VoidCallback onPickAll;
  final VoidCallback onPickUnrated;

  /// Picks the phrases rated 1–3 stars.
  final VoidCallback onPickWeak;
  final VoidCallback onClear;

  /// Studies the picked phrases.
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSelecting) ...[
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              AppButton(
                label: 'All',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                onPressed: onPickAll,
              ),
              AppButton(
                label: 'Not rated',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                onPressed: onPickUnrated,
              ),
              AppButton(
                label: '1–3 ★',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                onPressed: onPickWeak,
              ),
              AppButton(
                label: 'Clear',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: selection.isEmpty ? null : onClear,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: texts.length,
            itemBuilder: (_, index) => PhraseSelectRow(
              index: index,
              text: texts[index],
              stars: index < stars.length ? stars[index] : 0,
              isCurrent: index == currentIndex,
              isSelecting: isSelecting,
              isSelected: selection.contains(index),
              onTap: () => onTap(index),
            ),
          ),
        ),
        if (isSelecting) ...[
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            label: selection.isEmpty
                ? 'Study all phrases'
                : 'Study selected (${selection.length})',
            expand: true,
            onPressed: onApply,
          ),
        ],
      ],
    );
  }
}
