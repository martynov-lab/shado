import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';
import 'package:shado/widgets/app_tap_target.dart';

/// Checkbox with an indeterminate state when `value == null`.
class AppCheckbox extends StatefulWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticLabel,
  });

  /// `true` checked, `false` unchecked, `null` indeterminate.
  final bool? value;

  /// `null` disables the checkbox.
  final ValueChanged<bool>? onChanged;

  /// Label on the right; tapping it toggles the checkbox too.
  final String? label;
  final String? semanticLabel;

  bool get isEnabled => onChanged != null;

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox> {
  bool _hovered = false;
  bool _focused = false;

  void _toggle() => widget.onChanged?.call(!(widget.value ?? false));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.isEnabled;
    final indeterminate = widget.value == null;
    final checked = widget.value ?? false;
    final filled = checked || indeterminate;

    final box = AppFocusRing(
      visible: _focused,
      borderRadius: AppRadii.rXs,
      child: AnimatedContainer(
        duration: context.motion(AppDurations.fast),
        curve: AppCurves.standard,
        width: AppSizes.checkbox,
        height: AppSizes.checkbox,
        decoration: BoxDecoration(
          color: filled ? colors.primary : colors.surface,
          borderRadius: AppRadii.rXs,
          border: Border.all(
            color: filled
                ? colors.primary
                : (_hovered ? colors.primary : colors.borderStrong),
            width: AppSizes.borderThick,
          ),
        ),
        child: filled
            ? Icon(
                indeterminate ? Icons.remove_rounded : Icons.check_rounded,
                size: AppSizes.iconSm,
                color: colors.primaryOn,
              )
            : null,
      ),
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTapTarget(child: box),
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
      checked: checked,
      mixed: indeterminate,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? _toggle : null,
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
