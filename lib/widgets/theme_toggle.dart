import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_segmented_control.dart';

/// Appearance switch: light / dark / system.
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key, this.expand = false, this.labels});

  /// Stretches to the full available width.
  final bool expand;

  /// Whether to show text labels; defaults to tablet width and wider.
  final bool? labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(themeControllerProvider);
    final showLabels = labels ?? !context.isMobile;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) {
        return AppSegmentedControl<ThemeMode>(
          value: mode,
          expand: expand,
          semanticLabel: 'Оформление',
          onChanged: controller.setMode,
          segments: [
            AppSegment(
              value: ThemeMode.light,
              label: showLabels ? 'Светлая' : '',
              icon: Icons.light_mode_rounded,
              semanticLabel: 'Светлая тема',
            ),
            AppSegment(
              value: ThemeMode.dark,
              label: showLabels ? 'Тёмная' : '',
              icon: Icons.dark_mode_rounded,
              semanticLabel: 'Тёмная тема',
            ),
            AppSegment(
              value: ThemeMode.system,
              label: showLabels ? 'Системная' : '',
              icon: Icons.brightness_auto_rounded,
              semanticLabel: 'Как в системе',
            ),
          ],
        );
      },
    );
  }
}
