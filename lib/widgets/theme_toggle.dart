import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_segmented_control.dart';

/// Переключатель оформления: светлая / тёмная / системная.
///
/// Читает и пишет [ThemeController], поэтому выбор сразу сохраняется и
/// переживает перезапуск. Вставляется куда угодно — в настройки, в шапку
/// экрана, в галерею компонентов.
///
/// На узких экранах подписи скрываются и остаются одни иконки: три слова
/// в пилюлю на телефоне не помещаются.
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key, this.expand = false, this.labels});

  /// Растянуть на всю доступную ширину.
  final bool expand;

  /// Показывать текстовые подписи. По умолчанию — только от планшета и шире.
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
