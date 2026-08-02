import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

import 'settings_row.dart';

/// Строка выбора темы: переключатель светлая / тёмная / системная.
///
/// В отличие от остальных настроек здесь уже есть логика — [ThemeToggle]
/// читает и пишет тему приложения, поэтому выбор сразу применяется и
/// сохраняется.
class SettingsThemeRow extends StatelessWidget {
  const SettingsThemeRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsRow(
      icon: Icons.light_mode_outlined,
      title: 'Тема',
      // Только иконки: пилюля с тремя подписями не помещается в строку рядом с
      // заголовком в узкой колонке настроек.
      trailing: ThemeToggle(labels: false),
    );
  }
}
