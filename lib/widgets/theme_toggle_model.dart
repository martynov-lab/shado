import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/core_providers.dart';
import 'package:shado/theme/theme.dart';

/// The app theme choice for the toggle.
class ThemeToggleModel extends ElementaryModel {
  ThemeToggleModel(ProviderContainer container)
    : _controller = container.read(themeControllerProvider);

  final ThemeController _controller;

  ValueListenable<ThemeMode> get mode => _controller;

  void setMode(ThemeMode mode) => _controller.setMode(mode);
}
