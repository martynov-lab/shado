import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/app.dart';
import 'package:shado/core/audio/audio_service_setup.dart';
import 'package:shado/core/platform/platform_setup.dart';
import 'package:shado/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUpPlatform();
  // Сохранённую тему читаем до первого кадра — иначе при старте мелькнёт
  // системная вместо выбранной.
  final themeController = await ThemeController.restored();
  // Медиа-сессию (кнопки гарнитуры, экран блокировки) поднимаем до runApp —
  // audio_service требует единственный handler и инициализацию на старте. На
  // десктопе вернётся null, и провайдер останется с дефолтом.
  final audioHandler = await setUpAudioHandler();
  runApp(
    ProviderScope(
      overrides: [
        themeControllerProvider.overrideWithValue(themeController),
        if (audioHandler != null)
          audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const ShadoApp(),
    ),
  );
}
