import 'package:flutter/material.dart';

import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_switch_row.dart';
import 'settings_value.dart';

/// Learning section: the daily goal and reminders.
class LearningSettingsSection extends StatelessWidget {
  const LearningSettingsSection({
    super.key,
    required this.dailyGoalMinutes,
    required this.onEditGoal,
  });

  final int? dailyGoalMinutes;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    final goal = dailyGoalMinutes;

    return SettingsSection(
      title: 'Learning',
      rows: [
        SettingsRow(
          icon: Icons.schedule_rounded,
          title: 'Daily goal',
          trailing: SettingsValue(
            label: goal == null ? 'Not set' : '$goal min',
          ),
          onTap: onEditGoal,
        ),
        const SettingsSwitchRow(
          icon: Icons.notifications_outlined,
          title: 'Reminders',
          subtitle: 'Every day at 20:00',
          initialValue: true,
        ),
      ],
    );
  }
}
