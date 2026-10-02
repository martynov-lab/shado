import 'package:flutter/material.dart';

import 'package:shado/core/constants/app_constants.dart';

import '../../domain/entities/playback_settings.dart';
import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_stepper.dart';
import 'settings_switch_row.dart';
import 'settings_value.dart';

/// Playback section: speed, repeats, pause and the countdown.
class PlaybackSettingsSection extends StatelessWidget {
  const PlaybackSettingsSection({
    super.key,
    required this.settings,
    required this.onEditSpeed,
    required this.onRepeatsChanged,
    required this.onPauseChanged,
    required this.onCountdownChanged,
  });

  final PlaybackSettings settings;
  final VoidCallback onEditSpeed;
  final ValueChanged<int> onRepeatsChanged;
  final ValueChanged<bool> onPauseChanged;
  final ValueChanged<bool> onCountdownChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Playback',
      rows: [
        SettingsRow(
          icon: Icons.play_arrow_rounded,
          title: 'Default speed',
          trailing: SettingsValue(label: speedLabel(settings.defaultSpeed)),
          onTap: onEditSpeed,
        ),
        SettingsRow(
          icon: Icons.repeat_rounded,
          title: 'Repeats per loop',
          trailing: SettingsStepper(
            value: settings.repeatsInCycle,
            min: kMinRepeatsInCycle,
            max: kMaxRepeatsInCycle,
            formatValue: repeatsLabel,
            onChanged: onRepeatsChanged,
          ),
        ),
        SettingsSwitchRow(
          icon: Icons.pause_rounded,
          title: 'Pause between repeats',
          subtitle: '1 second',
          value: settings.pauseBetweenRepeats,
          onChanged: onPauseChanged,
        ),
        SettingsSwitchRow(
          icon: Icons.timer_outlined,
          title: '"3-2-1" countdown',
          value: settings.countdownEnabled,
          onChanged: onCountdownChanged,
        ),
      ],
    );
  }
}
