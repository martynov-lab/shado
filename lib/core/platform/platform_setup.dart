import 'dart:io';

import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Windows и Linux — единственные платформы, где `just_audio` и `sqflite`
/// остаются без нативной реализации; на Android/iOS/macOS плагины есть.
bool get isPluginlessDesktop => Platform.isWindows || Platform.isLinux;

/// Подставляет замены нативным плагинам на Windows/Linux: звук идёт через
/// `media_kit` (libmpv), база — через `sqlite3` по FFI. На остальных
/// платформах не делает ничего.
///
/// Вызывать до `runApp` и до первого обращения к плееру или БД.
void setUpPlatform() {
  if (!isPluginlessDesktop) return;
  JustAudioMediaKit.ensureInitialized(linux: true, windows: true);
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
