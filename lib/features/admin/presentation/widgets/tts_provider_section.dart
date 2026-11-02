import 'package:flutter/material.dart';

import '../../../settings/domain/entities/tts_provider_settings.dart';
import '../../../settings/presentation/widgets/settings_row.dart';
import '../../../settings/presentation/widgets/settings_section.dart';

/// The AI voice-over provider block: one row per provider, the active one
/// checked; a provider without keys on the server can't be picked.
class TtsProviderSection extends StatelessWidget {
  const TtsProviderSection({
    super.key,
    required this.settings,
    required this.onSelect,
  });

  /// `null` while the settings load.
  final TtsProviderSettings? settings;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final settings = this.settings;

    return SettingsSection(
      title: 'AI voice provider',
      rows: [
        if (settings == null)
          const SettingsRow(
            icon: Icons.record_voice_over_outlined,
            title: 'Loading…',
          )
        else
          for (final provider in settings.providers)
            SettingsRow(
              icon: Icons.record_voice_over_outlined,
              title: provider.label,
              subtitle: provider.ready ? null : 'Not configured on the server',
              trailing: provider.name == settings.active
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: provider.ready && provider.name != settings.active
                  ? () => onSelect(provider.name)
                  : null,
            ),
      ],
    );
  }
}
