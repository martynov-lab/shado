import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Settings row: an icon, a title with a hint and a trailing widget.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Makes the whole row tappable.
  final VoidCallback? onTap;

  /// Destructive action — the title and icon are painted in danger.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = danger ? colors.danger : colors.text2;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: AppRadii.rSm,
            ),
            child: Center(
              child: Icon(icon, size: AppSizes.iconSm, color: tint),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppText.label.copyWith(
                    color: danger ? colors.danger : colors.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    subtitle!,
                    style: AppText.caption.copyWith(color: colors.text3),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s3),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rSm,
        child: row,
      ),
    );
  }
}
