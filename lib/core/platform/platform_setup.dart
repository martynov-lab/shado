import 'dart:io';

import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Platforms without native `just_audio` and `sqflite`.
bool get isPluginlessDesktop => Platform.isWindows || Platform.isLinux;

/// Installs `media_kit` and `sqlite3` FFI replacements on Windows/Linux.
/// Call before `runApp`.
void setUpPlatform() {
  if (!isPluginlessDesktop) return;
  JustAudioMediaKit.ensureInitialized(linux: true, windows: true);
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
