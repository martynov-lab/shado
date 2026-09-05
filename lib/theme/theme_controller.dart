import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Selected theme (light, dark, system) persisted to disk.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController({ThemeMode initial = ThemeMode.system}) : super(initial);

  /// Creates the controller and waits for the stored choice to be read.
  static Future<ThemeController> restored() async {
    final controller = ThemeController();
    await controller.restore();
    return controller;
  }

  @visibleForTesting
  static const String storageKey = 'theme_mode';

  bool _disposed = false;

  /// Reads the stored mode; a storage error leaves the system one.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(storageKey);
      if (stored == null || _disposed) return;
      value = ThemeMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => ThemeMode.system,
      );
    } on Exception {
      // Stay on ThemeMode.system.
    }
  }

  /// Changes the theme and stores the choice.
  Future<void> setMode(ThemeMode mode) async {
    if (value == mode) return;
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, mode.name);
    } on Exception {
      // The theme is applied, but the choice will not survive a restart.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Theme controller; `main()` overrides it with a restored instance.
final themeControllerProvider = Provider<ThemeController>((ref) {
  final controller = ThemeController();
  unawaited(controller.restore());
  ref.onDispose(controller.dispose);
  return controller;
});
