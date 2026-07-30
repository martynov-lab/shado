import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/app.dart';
import 'package:shado/core/platform/platform_setup.dart';
import 'package:shado/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUpPlatform();
  // Сохранённую тему читаем до первого кадра — иначе при старте мелькнёт
  // системная вместо выбранной.
  final themeController = await ThemeController.restored();
  runApp(
    ProviderScope(
      overrides: [themeControllerProvider.overrideWithValue(themeController)],
      child: const ShadoApp(),
    ),
  );
}
