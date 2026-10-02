import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/widgets/theme_toggle.dart';
import 'package:shado/widgets/theme_toggle_model.dart';

ThemeToggleWidgetModel themeToggleWidgetModelFactory(BuildContext context) =>
    ThemeToggleWidgetModel(
      ThemeToggleModel(ProviderScope.containerOf(context, listen: false)),
    );

class ThemeToggleWidgetModel
    extends WidgetModel<ThemeToggle, ThemeToggleModel> {
  ThemeToggleWidgetModel(super.model);

  late final ValueNotifier<ThemeToggle> _config = ValueNotifier(widget);

  /// The latest toggle parameters; the parent may change them on resize.
  ValueListenable<ThemeToggle> get config => _config;

  @override
  void didUpdateWidget(ThemeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _config.value = widget;
  }

  @override
  void dispose() {
    _config.dispose();
    super.dispose();
  }

  ValueListenable<ThemeMode> get mode => model.mode;

  void setMode(ThemeMode mode) => model.setMode(mode);
}
