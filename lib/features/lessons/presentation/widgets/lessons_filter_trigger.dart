import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'lessons_filter_count_badge.dart';

/// A filter group chip; the badge shows how many values are selected.
class LessonsFilterTrigger extends StatelessWidget {
  const LessonsFilterTrigger({
    super.key,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = count > 0;
    final foreground = active ? colors.primary : colors.text2;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AppTapTarget(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.rPill,
            child: Container(
              height: AppSizes.controlSm,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              decoration: BoxDecoration(
                color: active ? colors.primarySoft : colors.surface,
                borderRadius: AppRadii.rPill,
                border: Border.all(
                  color: active ? colors.primary : colors.border,
                  width: AppSizes.borderThin,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppText.label.copyWith(color: foreground)),
                  if (active) ...[
                    const SizedBox(width: AppSpacing.s2),
                    LessonsFilterCountBadge(count),
                  ],
                  const SizedBox(width: AppSpacing.s1),
                  AppIcon(
                    AppIcons.chevronDown,
                    size: AppSizes.iconSm,
                    color: foreground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
