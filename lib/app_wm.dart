import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/app.dart';
import 'package:shado/app_model.dart';

AppWidgetModel appWidgetModelFactory(BuildContext context) =>
    AppWidgetModel(AppModel(ProviderScope.containerOf(context, listen: false)));

class AppWidgetModel extends WidgetModel<ShadoApp, AppModel>
    with WidgetsBindingObserver {
  AppWidgetModel(super.model);

  final ValueNotifier<bool> _reduceMotion = ValueNotifier(
    _platformReducesMotion(),
  );

  GoRouter get router => model.router;
  ValueListenable<ThemeMode> get themeMode => model.themeMode;

  /// The system asks for no animations; there is no MediaQuery above the app,
  /// so the flag is read from the platform.
  ValueListenable<bool> get reduceMotion => _reduceMotion;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reduceMotion.dispose();
    super.dispose();
  }

  @override
  void didChangeAccessibilityFeatures() =>
      _reduceMotion.value = _platformReducesMotion();

  /// Progress is sent when the app goes to the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(model.flushProgress());
    }
  }

  static bool _platformReducesMotion() => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;
}
