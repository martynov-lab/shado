import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Self-assessment under the card: how well the phrase is known.
class PhraseRatingRow extends StatelessWidget {
  const PhraseRatingRow({
    super.key,
    required this.stars,
    required this.onChanged,
  });

  final int stars;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'How well do you know it?',
          style: AppText.caption.copyWith(color: context.colors.text3),
        ),
        const SizedBox(height: AppSpacing.s1),
        AppStarRating(value: stars, onChanged: onChanged),
      ],
    );
  }
}
