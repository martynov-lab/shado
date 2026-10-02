import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'appearance_settings_section.dart';
import 'storage_settings_section.dart';

/// Settings sections in a single column.
class SettingsSingleColumnSections extends StatelessWidget {
  const SettingsSingleColumnSections({
    super.key,
    required this.playback,
    required this.learning,
    required this.language,
  });

  final Widget playback;
  final Widget learning;
  final Widget language;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppearanceSettingsSection(),
        const SizedBox(height: AppSpacing.s4),
        playback,
        const SizedBox(height: AppSpacing.s4),
        learning,
        const SizedBox(height: AppSpacing.s4),
        language,
        const SizedBox(height: AppSpacing.s4),
        const StorageSettingsSection(),
      ],
    );
  }
}
