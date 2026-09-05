import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';
import 'package:shado/widgets/app_tap_target.dart';

/// Fill of a selected chip.
enum AppChipStyle {
  /// Solid primary fill.
  on,

  /// Soft primarySoft fill.
  onSoft,
}

/// Label pill: lesson topic, level, filter tag. Without [onTap] it is not
/// interactive.
class AppChip extends StatefulWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.style = AppChipStyle.on,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final AppChipStyle style;
  final String? semanticLabel;

  bool get isInteractive => onTap != null;

  @override
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;

    final (Color background, Color foreground, Color borderColor) = switch ((
      selected,
      widget.style,
    )) {
      (true, AppChipStyle.on) => (
        colors.primary,
        colors.primaryOn,
        colors.primary,
      ),
      (true, AppChipStyle.onSoft) => (
        colors.primarySoft,
        colors.primary,
        colors.primarySoft,
      ),
      (false, _) => (colors.surface2, colors.text2, colors.border),
    };

    // Hover and press are blended into the fill.
    final overlayAlpha = _pressed
        ? AppOpacities.press
        : (_hovered ? AppOpacities.hover : 0.0);
    final tint = selected && widget.style == AppChipStyle.on
        ? colors.primaryOn
        : colors.primary;
    final fill = overlayAlpha == 0
        ? background
        : Color.alphaBlend(tint.withValues(alpha: overlayAlpha), background);

    final visual = AnimatedContainer(
      duration: context.motion(AppDurations.fast),
      curve: AppCurves.standard,
      height: AppSizes.controlSm,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: borderColor, width: AppSizes.borderThin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: AppSizes.iconSm, color: foreground),
            const SizedBox(width: AppSpacing.s2),
          ],
          Text(widget.label, style: AppText.label.copyWith(color: foreground)),
        ],
      ),
    );

    if (!widget.isInteractive) {
      return Semantics(
        label: widget.semanticLabel ?? widget.label,
        excludeSemantics: true,
        child: visual,
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: AppTapTarget(
        minSize: const Size.fromHeight(AppSizes.minTouchTarget),
        child: AppFocusRing(
          visible: _focused,
          borderRadius: AppRadii.rPill,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (value) => setState(() => _hovered = value),
              onHighlightChanged: (value) => setState(() => _pressed = value),
              onFocusChange: (value) => setState(
                () => _focused = value && AppFocusRing.isKeyboardFocus,
              ),
              borderRadius: AppRadii.rPill,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: visual,
            ),
          ),
        ),
      ),
    );
  }
}
