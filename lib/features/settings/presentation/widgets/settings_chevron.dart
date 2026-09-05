import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Chevron at the end of a settings row.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return AppIcon(
      AppIcons.chevronRight,
      size: AppSizes.iconSm,
      color: context.colors.text3,
    );
  }
}
