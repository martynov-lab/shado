import 'package:flutter/material.dart';

import '../screens/settings_wm.dart';
import 'settings_profile_card.dart';

/// Profile card that rebuilds when the profile changes.
class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({super.key, required this.wm});

  final SettingsWidgetModel wm;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: wm.profile,
      builder: (context, profile, _) => SettingsProfileCard(
        name: profile.name,
        email: profile.email,
        languageLabel: profile.languageLabel,
        onEdit: wm.editName,
      ),
    );
  }
}
