import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'settings_single_column_sections.dart';
import 'settings_two_column_sections.dart';

/// Settings on tablet and desktop: profile on top and sections in two
/// columns, or one column in a narrow window.
class SettingsTabletView extends StatelessWidget {
  const SettingsTabletView({
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

  static const double _twoColumnMinWidth = 720;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContent,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= _twoColumnMinWidth;

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.s6),
                children: [
                  Text(
                    'Settings',
                    style: AppText.h2.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  profile,
                  const SizedBox(height: AppSpacing.s5),
                  if (twoColumns)
                    SettingsTwoColumnSections(
                      playback: playback,
                      learning: learning,
                      language: language,
                    )
                  else
                    SettingsSingleColumnSections(
                      playback: playback,
                      learning: learning,
                      language: language,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
