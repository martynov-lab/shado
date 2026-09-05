import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Progress header: the title and an optional avatar on the right.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, this.showAvatar = true});

  /// Whether to show the user avatar on the right.
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Text('Прогресс', style: AppText.h2.copyWith(color: colors.text)),
        ),
        if (showAvatar)
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppBrand.signGradient,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
