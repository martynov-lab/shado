import 'package:flutter/material.dart';

import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_value.dart';

/// Раздел «Язык»: язык интерфейса и язык перевода.
class LanguageSettingsSection extends StatelessWidget {
  const LanguageSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsSection(
      title: 'Язык',
      rows: [
        SettingsRow(
          icon: Icons.language_rounded,
          title: 'Язык интерфейса',
          trailing: SettingsValue(label: 'Русский'),
        ),
        SettingsRow(
          icon: Icons.translate_rounded,
          title: 'Язык перевода',
          trailing: SettingsValue(label: 'Русский'),
        ),
      ],
    );
  }
}
