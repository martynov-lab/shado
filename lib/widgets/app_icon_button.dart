import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_button.dart';
import 'package:shado/widgets/app_focus_ring.dart';
import 'package:shado/widgets/app_tap_target.dart';

/// Icon button shape: a circle or a rounded square.
enum AppIconButtonShape { circle, square }

/// Button without a label; variants and sizes are shared with [AppButton].
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.variant = AppButtonVariant.ghost,
    this.size = AppButtonSize.md,
    this.shape = AppIconButtonShape.circle,
    this.loading = false,
    this.tooltip,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final AppIconButtonShape shape;
  final bool loading;

  /// Hover tooltip; defaults to [semanticLabel].
  final String? tooltip;

  bool get isEnabled => onPressed != null && !loading;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.isEnabled;

    final (double side, double iconSize) = switch (widget.size) {
      AppButtonSize.sm => (AppSizes.controlSm, AppSizes.iconSm),
      AppButtonSize.md => (AppSizes.controlMd, AppSizes.iconMd),
      AppButtonSize.lg => (AppSizes.controlLg, AppSizes.iconLg),
    };

    final borderRadius = switch (widget.shape) {
      AppIconButtonShape.circle => AppRadii.rPill,
      AppIconButtonShape.square => AppRadii.rMd,
    };

    final fg = widget.variant.foreground(colors);

    Widget visual = SizedBox.square(
      dimension: side,
      child: Material(
        color: widget.variant.background(
          colors,
          hovered: _hovered,
          pressed: _pressed,
        ),
        animationDuration: context.motion(AppDurations.fast),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: widget.variant.border(colors),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          onHover: (value) => setState(() => _hovered = value),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onFocusChange: (value) =>
              setState(() => _focused = value && AppFocusRing.isKeyboardFocus),
          canRequestFocus: enabled,
          borderRadius: borderRadius,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Center(
            child: widget.loading
                ? SizedBox.square(
                    dimension: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.spinnerStroke,
                      color: fg,
                    ),
                  )
                : Icon(widget.icon, size: iconSize, color: fg),
          ),
        ),
      ),
    );

    if (!enabled) {
      visual = Opacity(opacity: AppOpacities.disabled, child: visual);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.tooltip ?? widget.semanticLabel,
        child: AppTapTarget(
          child: AppFocusRing(
            visible: _focused,
            borderRadius: borderRadius,
            child: visual,
          ),
        ),
      ),
    );
  }
}
