import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';
import 'package:shado/widgets/app_tap_target.dart';

/// Насколько громко выглядит выбранный чип.
enum AppChipStyle {
  /// Заливка primary, текст на ней — для одного акцентного выбора.
  on,

  /// Мягкая заливка primarySoft — когда выбранных чипов в ряду много и
  /// сплошной фиолетовый ряд был бы криклив.
  onSoft,
}

/// Пилюля-ярлык: тема урока, уровень, метка фильтра.
///
/// Невыбранный чип держится на surface2 с тонкой обводкой; выбранный
/// заливается по [style]. Если [onTap] равен `null`, чип неинтерактивен —
/// просто ярлык.
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

    // Наведение и нажатие подмешиваем к заливке, чтобы не заводить отдельные
    // токены на каждое сочетание «выбран × состояние».
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
