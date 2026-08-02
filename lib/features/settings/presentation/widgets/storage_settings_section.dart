import 'package:flutter/material.dart';

import 'settings_chevron.dart';
import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_switch_row.dart';

/// Раздел «Данные и хранилище»: занятое место, офлайн-загрузка, резервная копия
/// и очистка кэша.
class StorageSettingsSection extends StatelessWidget {
  const StorageSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsSection(
      title: 'Данные и хранилище',
      rows: [
        SettingsRow(
          icon: Icons.storage_rounded,
          title: 'Использовано',
          subtitle: '240 МБ · 14 уроков',
        ),
        SettingsSwitchRow(
          icon: Icons.download_rounded,
          title: 'Скачивать аудио офлайн',
          initialValue: true,
        ),
        SettingsRow(
          icon: Icons.backup_outlined,
          title: 'Резервная копия',
          trailing: SettingsChevron(),
        ),
        SettingsRow(
          icon: Icons.delete_outline_rounded,
          title: 'Очистить кэш',
          danger: true,
          trailing: SettingsChevron(),
        ),
      ],
    );
  }
}
