import 'package:flutter/material.dart';

import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_switch_row.dart';
import 'settings_value.dart';

/// Раздел «Обучение»: дневная цель и напоминания.
class LearningSettingsSection extends StatelessWidget {
  const LearningSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsSection(
      title: 'Обучение',
      rows: [
        SettingsRow(
          icon: Icons.schedule_rounded,
          title: 'Дневная цель',
          trailing: SettingsValue(label: '15 мин'),
        ),
        SettingsSwitchRow(
          icon: Icons.notifications_outlined,
          title: 'Напоминания',
          subtitle: 'Каждый день в 20:00',
          initialValue: true,
        ),
      ],
    );
  }
}
