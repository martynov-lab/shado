import 'dart:io';

import 'package:audio_service/audio_service.dart';

import 'shadowing_audio_handler.dart';

/// Whether the platform provides a system media session.
bool get _supportsMediaSession => Platform.isAndroid || Platform.isIOS;

/// Starts the media session before `runApp`; `null` on unsupported platforms.
Future<ShadowingAudioHandler?> setUpAudioHandler() async {
  if (!_supportsMediaSession) return null;
  return AudioService.init(
    builder: ShadowingAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.shado.playback',
      androidNotificationChannelName: 'Lesson playback',
      androidStopForegroundOnPause: false,
    ),
  );
}
