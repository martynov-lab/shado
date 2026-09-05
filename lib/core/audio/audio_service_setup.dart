import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shadowing_audio_handler.dart';

/// Whether the platform provides a system media session.
bool get _supportsMediaSession => Platform.isAndroid || Platform.isIOS;

/// Media session handler; `null` where there is none — desktop and tests.
final audioHandlerProvider = Provider<ShadowingAudioHandler?>((ref) => null);

/// Starts the media session before `runApp`; `null` on unsupported platforms.
Future<ShadowingAudioHandler?> setUpAudioHandler() async {
  if (!_supportsMediaSession) return null;
  return AudioService.init(
    builder: ShadowingAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.shado.playback',
      androidNotificationChannelName: 'Воспроизведение урока',
    ),
  );
}
