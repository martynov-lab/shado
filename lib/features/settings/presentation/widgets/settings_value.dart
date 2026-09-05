import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Value on the right of a settings row: text and a chevron.
class SettingsValue extends StatelessWidget {
  const SettingsValue({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.label.copyWith(color: colors.text3)),
        const SizedBox(width: AppSpacing.s1),
        AppIcon(AppIcons.chevronRight, size: AppSizes.iconSm, color: colors.text3),
      ],
    );
  }
}
