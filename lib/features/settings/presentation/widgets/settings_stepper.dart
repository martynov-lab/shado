import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// A minus/plus stepper for numeric settings.
class SettingsStepper extends StatelessWidget {
  const SettingsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 9,
    this.formatValue,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// How to render the centered value; defaults to the number itself.
  final String Function(int value)? formatValue;

  void _change(int delta) {
    final next = (value + delta).clamp(min, max);
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s1 - AppSizes.borderThin),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: colors.border, width: AppSizes.borderThin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            semanticLabel: 'Уменьшить',
            onPressed: value > min ? () => _change(-1) : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              formatValue?.call(value) ?? '$value',
              textAlign: TextAlign.center,
              style: AppText.monoTime.copyWith(color: colors.text),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            semanticLabel: 'Увеличить',
            onPressed: value < max ? () => _change(1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 26,
            height: 26,
            child: Icon(
              icon,
              size: AppSizes.iconSm,
              color: enabled ? colors.text2 : colors.text3,
            ),
          ),
        ),
      ),
    );
  }
}
