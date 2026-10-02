import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'settings_step_button.dart';

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
          SettingsStepButton(
            icon: Icons.remove_rounded,
            semanticLabel: 'Decrease',
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
          SettingsStepButton(
            icon: Icons.add_rounded,
            semanticLabel: 'Increase',
            onPressed: value < max ? () => _change(1) : null,
          ),
        ],
      ),
    );
  }
}
