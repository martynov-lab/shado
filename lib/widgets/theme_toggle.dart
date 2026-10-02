import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_segmented_control.dart';
import 'package:shado/widgets/theme_toggle_wm.dart';

/// Appearance switch: light / dark / system.
class ThemeToggle extends ElementaryWidget<ThemeToggleWidgetModel> {
  const ThemeToggle({super.key, this.expand = false, this.labels})
    : super(themeToggleWidgetModelFactory);

  /// Stretches to the full available width.
  final bool expand;

  /// Whether to show text labels; defaults to tablet width and wider.
  final bool? labels;

  @override
  Widget build(ThemeToggleWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([wm.mode, wm.config]),
      builder: (context, _) {
        final mode = wm.mode.value;
        final config = wm.config.value;
        final showLabels = config.labels ?? !context.isMobile;
        return AppSegmentedControl<ThemeMode>(
          value: mode,
          expand: config.expand,
          semanticLabel: 'Appearance',
          onChanged: wm.setMode,
          segments: [
            AppSegment(
              value: ThemeMode.light,
              label: showLabels ? 'Light' : '',
              icon: Icons.light_mode_rounded,
              semanticLabel: 'Light theme',
            ),
            AppSegment(
              value: ThemeMode.dark,
              label: showLabels ? 'Dark' : '',
              icon: Icons.dark_mode_rounded,
              semanticLabel: 'Dark theme',
            ),
            AppSegment(
              value: ThemeMode.system,
              label: showLabels ? 'System' : '',
              icon: Icons.brightness_auto_rounded,
              semanticLabel: 'Same as system',
            ),
          ],
        );
      },
    );
  }
}
