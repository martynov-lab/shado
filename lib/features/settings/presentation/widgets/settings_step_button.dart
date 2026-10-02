import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Round minus or plus button of the settings stepper.
class SettingsStepButton extends StatelessWidget {
  const SettingsStepButton({
    super.key,
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
