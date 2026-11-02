import 'dart:math';

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// The phrase card. The main text is the phrase or, face down in Recall, its
/// translation; a change of [faceKey] turns the card over.
class PhraseCard extends StatelessWidget {
  const PhraseCard({
    super.key,
    required this.faceKey,
    required this.text,
    this.secondary,
    this.hint,
    this.onTap,
  });

  /// Identifies the shown face; a new value plays the flip.
  final Object faceKey;

  final String text;

  /// Smaller text under the main one, such as the translation.
  final String? secondary;

  /// A muted note above the text, such as what to do with the card.
  final String? hint;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final secondary = this.secondary;
    final hint = this.hint;

    return AnimatedSwitcher(
      duration: context.motion(AppDurations.slow),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (_, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY((1 - animation.value) * pi / 2),
          child: child,
        ),
      ),
      child: GestureDetector(
        key: ValueKey(faceKey),
        onTap: onTap,
        child: AppCard(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hint != null) ...[
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(color: colors.text3),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                  ],
                  SelectableText(
                    text,
                    textAlign: TextAlign.center,
                    style: AppText.h2.copyWith(color: colors.text),
                  ),
                  if (secondary != null) ...[
                    const SizedBox(height: AppSpacing.s3),
                    SelectableText(
                      secondary,
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: colors.text2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
