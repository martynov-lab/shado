import 'package:flutter/material.dart';

import 'settings_section.dart';
import 'settings_theme_row.dart';

/// Appearance section: the app theme picker.
class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsSection(
      title: 'Оформление',
      rows: [SettingsThemeRow()],
    );
  }
}
