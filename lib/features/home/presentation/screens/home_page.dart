import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

import '../widgets/home_desktop_view.dart';
import '../widgets/home_mobile_view.dart';
import '../widgets/home_tablet_view.dart';
import 'home_wm.dart';

/// Home screen: greeting, continue card, stats, weekly goal and lessons.
class HomePage extends ElementaryWidget<HomeWidgetModel> {
  const HomePage({super.key}) : super(homeWidgetModelFactory);

  static const String routePath = '/home';

  @override
  Widget build(HomeWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([wm.overview, wm.heroProgress]),
      builder: (_, _) => AppAdaptiveLayout(
        mobile: (_) => HomeMobileView(
          overview: wm.overview.value,
          heroProgress: wm.heroProgress.value,
          onOpenLessons: wm.openLessons,
          onOpenLesson: wm.openLesson,
        ),
        tablet: (_) => HomeTabletView(
          overview: wm.overview.value,
          heroProgress: wm.heroProgress.value,
          onOpenLessons: wm.openLessons,
          onOpenLesson: wm.openLesson,
        ),
        desktop: (_) => HomeDesktopView(
          overview: wm.overview.value,
          heroProgress: wm.heroProgress.value,
          onOpenLessons: wm.openLessons,
          onOpenLesson: wm.openLesson,
        ),
      ),
    );
  }
}
