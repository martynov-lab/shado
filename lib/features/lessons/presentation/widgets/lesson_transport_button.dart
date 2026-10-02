import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// A round player button; it is disabled when [onTap] is `null`.
class LessonTransportButton extends StatelessWidget {
  const LessonTransportButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.size = AppSizes.controlMd,
  });

  final AppIcons icon;
  final String semanticLabel;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        child: Opacity(
          opacity: enabled ? 1 : AppOpacities.disabled,
          child: Material(
            color: background,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: AppIcon(
                    icon,
                    size: AppSizes.iconMd,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
