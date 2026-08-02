import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Компактный счётчик «− N +» для числовых настроек (например, повторов в цикле).
///
/// Значение пока живёт локально и не сохраняется — привязку к настройкам
/// добавим отдельной задачей.
class SettingsStepper extends StatefulWidget {
  const SettingsStepper({
    super.key,
    required this.initialValue,
    this.min = 1,
    this.max = 9,
  });

  final int initialValue;
  final int min;
  final int max;

  @override
  State<SettingsStepper> createState() => _SettingsStepperState();
}

class _SettingsStepperState extends State<SettingsStepper> {
  late int _value = widget.initialValue;

  void _change(int delta) {
    setState(() {
      _value = (_value + delta).clamp(widget.min, widget.max);
    });
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
            onPressed: _value > widget.min ? () => _change(-1) : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$_value',
              textAlign: TextAlign.center,
              style: AppText.monoTime.copyWith(color: colors.text),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            semanticLabel: 'Увеличить',
            onPressed: _value < widget.max ? () => _change(1) : null,
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
