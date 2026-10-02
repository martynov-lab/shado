import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/widgets/widgets.dart';

import '../widgets/progress_desktop_view.dart';
import '../widgets/progress_error_view.dart';
import '../widgets/progress_mobile_view.dart';
import '../widgets/progress_tablet_view.dart';
import 'progress_wm.dart';

/// Progress screen: streak, stats, minutes chart, heatmap and the goal.
class ProgressPage extends ElementaryWidget<ProgressWidgetModel> {
  const ProgressPage({super.key}) : super(progressWidgetModelFactory);

  static const String routePath = '/progress';

  @override
  Widget build(ProgressWidgetModel wm) {
    return ValueListenableBuilder(
      valueListenable: wm.overview,
      builder: (_, overview, _) => switch (overview) {
        AsyncFailed(:final error) => ProgressErrorView(
          message: '$error',
          onRetry: () => unawaited(wm.retry()),
        ),
        AsyncReady(:final value) => AppAdaptiveLayout(
          mobile: (_) =>
              ProgressMobileView(overview: value, onOpenLesson: wm.openLesson),
          tablet: (_) =>
              ProgressTabletView(overview: value, onOpenLesson: wm.openLesson),
          desktop: (_) =>
              ProgressDesktopView(overview: value, onOpenLesson: wm.openLesson),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
