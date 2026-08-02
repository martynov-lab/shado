import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

import '../widgets/progress_desktop_view.dart';
import '../widgets/progress_mobile_view.dart';
import '../widgets/progress_tablet_view.dart';

/// Экран прогресса: серия занятий, статистика, график минут, тепловая карта
/// активности, уровень и достижения.
///
/// Каркас (Scaffold, навигация) даёт [MainShell]; раскладку выбирает
/// [AppAdaptiveLayout]. Данные пока демонстрационные — реальные метрики
/// подключим отдельной задачей.
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  static const String routePath = '/progress';

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveLayout(
      mobile: (context) => const ProgressMobileView(),
      tablet: (context) => const ProgressTabletView(),
      desktop: (context) => const ProgressDesktopView(),
    );
  }
}
