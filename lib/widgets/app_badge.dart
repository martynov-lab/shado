import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Meaning of a badge on a lesson card.
enum AppBadgeVariant {
  /// Freshly added lesson — green.
  fresh,

  /// Due for a repeat — amber.
  due,

  /// On a streak — pink.
  hot,

  /// Neutral status — grey-lilac.
  neutral,
}

/// Status pill badge; not interactive.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.fresh,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (Color background, Color foreground) = switch (variant) {
      AppBadgeVariant.fresh => (colors.successSoft, colors.success),
      AppBadgeVariant.due => (colors.warningSoft, colors.warning),
      AppBadgeVariant.hot => (colors.accentSoft, colors.accent),
      AppBadgeVariant.neutral => (colors.surface2, colors.text2),
    };

    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s1,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadii.rPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconSm, color: foreground),
              const SizedBox(width: AppSpacing.s1),
            ],
            Text(label, style: AppText.caption.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}
