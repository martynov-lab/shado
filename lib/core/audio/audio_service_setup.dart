import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shadowing_audio_handler.dart';

/// Медиа-сессия есть там, где ОС доставляет кнопки гарнитуры и рисует плеер на
/// экране блокировки, — это Android и iOS. На Windows/Linux звук идёт через
/// media_kit, audio_service там не поддержан: [audioHandlerProvider] остаётся
/// `null`, и урок работает как прежде — без системной сессии.
bool get _supportsMediaSession => Platform.isAndroid || Platform.isIOS;

/// Хэндлер системной медиа-сессии. `null` там, где сессии нет (десктоп, тесты):
/// контроллер урока тогда просто её не трогает.
final audioHandlerProvider = Provider<ShadowingAudioHandler?>((ref) => null);

/// Поднимает медиа-сессию до `runApp`. Возвращает `null` на платформах без
/// поддержки — вызывающий подставит результат в [audioHandlerProvider].
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
