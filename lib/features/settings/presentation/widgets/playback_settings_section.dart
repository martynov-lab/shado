import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/playback_settings.dart';
import '../controllers/playback_settings_controller.dart';
import 'playback_speed_sheet.dart';
import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_stepper.dart';
import 'settings_switch_row.dart';
import 'settings_value.dart';

/// Раздел «Воспроизведение»: скорость по умолчанию, число повторов, пауза и
/// обратный отсчёт. Всё сохраняется локально и применяется плеером урока.
class PlaybackSettingsSection extends ConsumerWidget {
  const PlaybackSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Пока настройки грузятся — показываем значения по умолчанию, а не спиннер:
    // раздел не должен «мигать» на первом кадре.
    final settings =
        ref.watch(playbackSettingsControllerProvider).value ??
        const PlaybackSettings();
    final controller = ref.read(playbackSettingsControllerProvider.notifier);

    return SettingsSection(
      title: 'Воспроизведение',
      rows: [
        SettingsRow(
          icon: Icons.play_arrow_rounded,
          title: 'Скорость по умолчанию',
          trailing: SettingsValue(label: speedLabel(settings.defaultSpeed)),
          onTap: () => _editSpeed(context, ref, settings.defaultSpeed),
        ),
        SettingsRow(
          icon: Icons.repeat_rounded,
          title: 'Повторов в цикле',
          trailing: SettingsStepper(
            value: settings.repeatsInCycle,
            min: kMinRepeatsInCycle,
            max: kMaxRepeatsInCycle,
            formatValue: repeatsLabel,
            onChanged: controller.setRepeatsInCycle,
          ),
        ),
        SettingsSwitchRow(
          icon: Icons.pause_rounded,
          title: 'Пауза между повторами',
          subtitle: '1 секунда',
          value: settings.pauseBetweenRepeats,
          onChanged: controller.setPauseBetweenRepeats,
        ),
        SettingsSwitchRow(
          icon: Icons.timer_outlined,
          title: 'Обратный отсчёт «3-2-1»',
          value: settings.countdownEnabled,
          onChanged: controller.setCountdownEnabled,
        ),
      ],
    );
  }

  Future<void> _editSpeed(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    final selected = await showAppBottomSheet<double>(
      context: context,
      title: 'Скорость по умолчанию',
      builder: (_) => PlaybackSpeedSheet(current: current),
    );
    if (selected == null) return;
    await ref
        .read(playbackSettingsControllerProvider.notifier)
        .setDefaultSpeed(selected);
  }
}
