import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum AppButtonVariant { primary, secondary, ghost }

/// Reference component: a pill button built only from design tokens.
/// Use it as the template for every other widget in the library — read colors
/// from `context.colors`, sizes from `AppSpacing`/`AppRadii`, text from `AppText`.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;

  /// If true, stretches to the full width of its parent.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final (Color bg, Color fg, Color borderColor) = switch (variant) {
      AppButtonVariant.primary => (c.primary, c.primaryOn, Colors.transparent),
      AppButtonVariant.secondary => (c.primarySoft, c.primary, Colors.transparent),
      AppButtonVariant.ghost => (Colors.transparent, c.text2, c.borderStrong),
    };

    final button = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.rPill,
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: AppRadii.rPill,
        onTap: onPressed,
        overlayColor: WidgetStatePropertyAll(
          variant == AppButtonVariant.primary
              ? Colors.white.withValues(alpha: 0.12)
              : c.primary.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s3 + 2,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.s2),
              ],
              Text(label, style: AppText.label.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
