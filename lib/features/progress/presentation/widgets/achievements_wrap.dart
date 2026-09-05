import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'achievement_badge.dart';

/// Wrapping set of achievement badges.
class AchievementsWrap extends StatelessWidget {
  const AchievementsWrap({super.key, required this.items});

  final List<(AppIcons, String, bool)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      children: [
        for (final item in items)
          AchievementBadge(
            icon: item.$1,
            label: item.$2,
            locked: item.$3,
          ),
      ],
    );
  }
}
