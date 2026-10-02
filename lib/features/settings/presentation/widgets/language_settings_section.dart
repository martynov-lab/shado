import 'package:flutter/material.dart';

import 'settings_row.dart';
import 'settings_section.dart';
import 'settings_value.dart';

/// Language section: studied, interface and translation languages.
class LanguageSettingsSection extends StatelessWidget {
  const LanguageSettingsSection({
    super.key,
    required this.studiedLanguageLabel,
    required this.onEditLanguage,
    required this.onEditVoice,
    this.ttsVoiceLabel,
  });

  final String studiedLanguageLabel;
  final VoidCallback onEditLanguage;
  final VoidCallback onEditVoice;

  /// Pass `null` to hide the voice row (it is for the owner only).
  final String? ttsVoiceLabel;

  @override
  Widget build(BuildContext context) {
    final voiceLabel = ttsVoiceLabel;

    return SettingsSection(
      title: 'Language',
      rows: [
        SettingsRow(
          icon: Icons.school_outlined,
          title: 'Studied language',
          trailing: SettingsValue(label: studiedLanguageLabel),
          onTap: onEditLanguage,
        ),
        if (voiceLabel != null)
          SettingsRow(
            icon: Icons.record_voice_over_outlined,
            title: 'AI voiceover voice',
            trailing: SettingsValue(label: voiceLabel),
            onTap: onEditVoice,
          ),
        const SettingsRow(
          icon: Icons.language_rounded,
          title: 'Interface language',
          trailing: SettingsValue(label: 'English'),
        ),
        const SettingsRow(
          icon: Icons.translate_rounded,
          title: 'Translation language',
          trailing: SettingsValue(label: 'English'),
        ),
      ],
    );
  }
}
