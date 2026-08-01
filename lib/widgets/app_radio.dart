import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';
import 'package:shado/widgets/app_tap_target.dart';

/// Переключатель одного варианта из группы.
///
/// Группа задаётся общим [groupValue]: у выбранного элемента `value ==
/// groupValue`. Тип [T] — что угодно сравнимое (обычно enum).
///
/// ```dart
/// AppRadio<Speed>(
///   value: Speed.slow,
///   groupValue: speed,
///   label: '0.75×',
///   onChanged: (value) => setState(() => speed = value),
/// )
/// ```
class AppRadio<T> extends StatefulWidget {
  const AppRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.semanticLabel,
  });

  final T value;
  final T? groupValue;

  /// `null` выключает переключатель.
  final ValueChanged<T>? onChanged;

  final String? label;
  final String? semanticLabel;

  bool get isSelected => value == groupValue;
  bool get isEnabled => onChanged != null;

  @override
  State<AppRadio<T>> createState() => _AppRadioState<T>();
}

class _AppRadioState<T> extends State<AppRadio<T>> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.isEnabled;
    final selected = widget.isSelected;

    final dial = AppFocusRing(
      visible: _focused,
      borderRadius: AppRadii.rPill,
      child: AnimatedContainer(
        duration: context.motion(AppDurations.fast),
        curve: AppCurves.standard,
        width: AppSizes.radio,
        height: AppSizes.radio,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? colors.primary
                : (_hovered ? colors.primary : colors.borderStrong),
            width: AppSizes.borderThick,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: context.motion(AppDurations.fast),
            curve: AppCurves.standard,
            width: selected ? AppSizes.radioDot : 0,
            height: selected ? AppSizes.radioDot : 0,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTapTarget(child: dial),
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
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? () => widget.onChanged!(widget.value) : null,
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
