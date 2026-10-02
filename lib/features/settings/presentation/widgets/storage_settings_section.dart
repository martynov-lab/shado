import 'package:flutter/material.dart';

import 'settings_chevron.dart';
import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_switch_row.dart';

/// Data and storage section: space, offline, backup and cache cleanup.
class StorageSettingsSection extends StatelessWidget {
  const StorageSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsSection(
      title: 'Data and storage',
      rows: [
        SettingsRow(
          icon: Icons.storage_rounded,
          title: 'Used',
          subtitle: '240 MB · 14 lessons',
        ),
        SettingsSwitchRow(
          icon: Icons.download_rounded,
          title: 'Download audio for offline',
          initialValue: true,
        ),
        SettingsRow(
          icon: Icons.backup_outlined,
          title: 'Backup',
          trailing: SettingsChevron(),
        ),
        SettingsRow(
          icon: Icons.delete_outline_rounded,
          title: 'Clear cache',
          danger: true,
          trailing: SettingsChevron(),
        ),
      ],
    );
  }
}
