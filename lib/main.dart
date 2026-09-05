import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/app.dart';
import 'package:shado/core/audio/audio_service_setup.dart';
import 'package:shado/core/platform/platform_setup.dart';
import 'package:shado/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUpPlatform();
  // Read the stored theme before the first frame.
  final themeController = await ThemeController.restored();
  // Start the media session before runApp; desktop returns `null`.
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
