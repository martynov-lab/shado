import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';
import 'package:shado/widgets/app_tap_target.dart';

/// Тумблер «включено / выключено».
///
/// Трек красится в primary во включённом состоянии и в waveOff — в
/// выключенном: тот же серо-сиреневый, что у неактивной части волны, поэтому
/// выключенный тумблер читается одинаково в обеих темах.
class AppSwitch extends StatefulWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticLabel,
  });

  final bool value;

  /// `null` выключает тумблер.
  final ValueChanged<bool>? onChanged;

  /// Подпись справа. Нажатие по ней тоже переключает.
  final String? label;
  final String? semanticLabel;

  bool get isEnabled => onChanged != null;

  @override
  State<AppSwitch> createState() => _AppSwitchState();
}

class _AppSwitchState extends State<AppSwitch> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.isEnabled;
    final on = widget.value;

    final trackColor = on
        ? (_hovered ? colors.primaryHover : colors.primary)
        : (_hovered
              ? Color.alphaBlend(
                  colors.primary.withValues(alpha: AppOpacities.hover),
                  colors.waveOff,
                )
              : colors.waveOff);

    final track = AppFocusRing(
      visible: _focused,
      borderRadius: AppRadii.rPill,
      child: AnimatedContainer(
        duration: context.motion(AppDurations.base),
        curve: AppCurves.standard,
        width: AppSizes.switchWidth,
        height: AppSizes.switchHeight,
        padding: const EdgeInsets.all(AppSpacing.s1 - AppSizes.borderThin),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: AppRadii.rPill,
        ),
        child: AnimatedAlign(
          duration: context.motion(AppDurations.base),
          curve: AppCurves.standard,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: AppSizes.switchThumb,
            height: AppSizes.switchThumb,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              boxShadow: context.shadows.e1,
            ),
          ),
        ),
      ),
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTapTarget(child: track),
        if (widget.label != null)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s2),
              child: Text(
                widget.label!,
                style: AppText.body.copyWith(color: colors.text),
              ),
            ),
          ),
      ],
    );

    if (!enabled) {
      content = Opacity(opacity: AppOpacities.disabled, child: content);
    }

    return Semantics(
      toggled: on,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? () => widget.onChanged!(!on) : null,
          onHover: (value) => setState(() => _hovered = value),
          onFocusChange: (value) =>
              setState(() => _focused = value && AppFocusRing.isKeyboardFocus),
          canRequestFocus: enabled,
          borderRadius: AppRadii.rSm,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: content,
        ),
      ),
    );
  }
}
