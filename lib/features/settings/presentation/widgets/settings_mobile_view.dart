import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'appearance_settings_section.dart';
import 'storage_settings_section.dart';

/// Settings on phone: profile and sections in one scrollable column.
class SettingsMobileView extends StatelessWidget {
  const SettingsMobileView({
    super.key,
    required this.profile,
    required this.playback,
    required this.learning,
    required this.language,
  });

  final Widget profile;
  final Widget playback;
  final Widget learning;
  final Widget language;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s5,
          AppSpacing.s5,
          AppSpacing.s6,
        ),
        children: [
          Text('Settings', style: AppText.h2.copyWith(color: colors.text)),
          const SizedBox(height: AppSpacing.s5),
          profile,
          const SizedBox(height: AppSpacing.s4),
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
      ),
    );
  }
}
