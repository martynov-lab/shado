import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Шеврон-стрелка в конце строки настройки — намёк, что строка ведёт дальше.
/// Экран назначения подключим отдельной задачей.
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
