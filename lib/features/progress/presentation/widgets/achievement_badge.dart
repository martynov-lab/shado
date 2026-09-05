import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Achievement badge: icon and label; a locked one shows a padlock.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.icon,
    required this.label,
    this.locked = false,
  });

  final AppIcons icon;
  final String label;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = locked ? colors.text3 : colors.primary;

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: locked ? colors.surface2 : colors.primarySoft,
              borderRadius: AppRadii.rMd,
            ),
            child: Center(
              child: AppIcon(
                locked ? AppIcons.lock : icon,
                size: AppSizes.iconLg,
                color: tint,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            label,
            style: AppText.caption.copyWith(color: colors.text2),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
