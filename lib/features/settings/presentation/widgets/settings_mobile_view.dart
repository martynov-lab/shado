import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'appearance_settings_section.dart';
import 'language_settings_section.dart';
import 'learning_settings_section.dart';
import 'playback_settings_section.dart';
import 'settings_profile_card.dart';
import 'storage_settings_section.dart';

/// Settings on phone: profile and sections in one scrollable column.
class SettingsMobileView extends StatelessWidget {
  const SettingsMobileView({
    super.key,
    required this.name,
    required this.email,
    required this.onEditName,
    this.languageLabel,
  });

  final String name;
  final String email;
  final VoidCallback onEditName;

  /// Studied language label; `null` hides the badge.
  final String? languageLabel;

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
          Text('Настройки', style: AppText.h2.copyWith(color: colors.text)),
          const SizedBox(height: AppSpacing.s5),
          SettingsProfileCard(
            name: name,
            email: email,
            languageLabel: languageLabel,
            onEdit: onEditName,
          ),
          const SizedBox(height: AppSpacing.s4),
          const AppearanceSettingsSection(),
          const SizedBox(height: AppSpacing.s4),
          const PlaybackSettingsSection(),
          const SizedBox(height: AppSpacing.s4),
          const LearningSettingsSection(),
          const SizedBox(height: AppSpacing.s4),
          const LanguageSettingsSection(),
          const SizedBox(height: AppSpacing.s4),
          const StorageSettingsSection(),
        ],
      ),
    );
  }
}
