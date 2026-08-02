import 'package:flutter/material.dart';

import 'settings_section.dart';
import 'settings_theme_row.dart';

/// Раздел «Оформление»: выбор темы приложения.
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
