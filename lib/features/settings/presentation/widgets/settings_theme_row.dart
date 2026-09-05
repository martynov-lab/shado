import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

import 'settings_row.dart';

/// Theme row: light / dark / system.
class SettingsThemeRow extends StatelessWidget {
  const SettingsThemeRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsRow(
      icon: Icons.light_mode_outlined,
      title: 'Тема',
      // Icons only: labels do not fit into a settings row.
      trailing: ThemeToggle(labels: false),
    );
  }
}
