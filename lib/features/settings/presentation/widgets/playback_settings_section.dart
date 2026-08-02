import 'package:flutter/material.dart';

import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_stepper.dart';
import 'settings_switch_row.dart';
import 'settings_value.dart';

/// Раздел «Воспроизведение»: скорость, число повторов, пауза и обратный отсчёт.
class PlaybackSettingsSection extends StatelessWidget {
  const PlaybackSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsSection(
      title: 'Воспроизведение',
      rows: [
        SettingsRow(
          icon: Icons.play_arrow_rounded,
          title: 'Скорость по умолчанию',
          trailing: SettingsValue(label: '1.0×'),
        ),
        SettingsRow(
          icon: Icons.repeat_rounded,
          title: 'Повторов в цикле',
          trailing: SettingsStepper(initialValue: 3),
        ),
        SettingsSwitchRow(
          icon: Icons.pause_rounded,
          title: 'Пауза между повторами',
          subtitle: '1 секунда',
          initialValue: true,
        ),
        SettingsSwitchRow(
          icon: Icons.timer_outlined,
          title: 'Обратный отсчёт «3-2-1»',
          initialValue: false,
        ),
      ],
    );
  }
}
