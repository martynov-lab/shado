import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/app_wm.dart';
import 'package:shado/theme/theme.dart';

/// The app root: theme and router.
class ShadoApp extends ElementaryWidget<AppWidgetModel> {
  const ShadoApp({super.key}) : super(appWidgetModelFactory);

  @override
  Widget build(AppWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([wm.themeMode, wm.reduceMotion]),
      builder: (_, _) => MaterialApp.router(
        title: 'Shado',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: wm.themeMode.value,
        themeAnimationDuration: wm.reduceMotion.value
            ? Duration.zero
            : AppDurations.slow,
        themeAnimationCurve: AppCurves.standard,
        routerConfig: wm.router,
      ),
    );
  }
}
