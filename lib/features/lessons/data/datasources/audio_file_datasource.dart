import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/failures.dart';

/// Работа с аудиофайлом урока: импорт в приложение и чтение длительности.
abstract interface class AudioFileDataSource {
  /// Копирует выбранный файл в каталог приложения и возвращает новый путь.
  Future<String> importAudio({
    required String lessonId,
    required String sourcePath,
  });

  Future<int> resolveDurationMs(String audioPath);

  /// Удаляет локальную копию аудио (и кеш волны рядом с ней).
  Future<void> deleteAudio(String audioPath);
}

class LocalAudioFileDataSource implements AudioFileDataSource {
  const LocalAudioFileDataSource();

  static const String _audioDirName = 'audio';

  /// Каталог с аудио уроков: `ApplicationDocumentsDirectory/audio`.
  static Future<Directory> audioDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, _audioDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<String> importAudio({
    required String lessonId,
    required String sourcePath,
  }) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        throw AudioFailure('Файл $sourcePath не найден');
      }
      final extension = p.extension(sourcePath).replaceFirst('.', '');
      final dir = await audioDirectory();
      final targetPath = p.join(
        dir.path,
        extension.isEmpty ? lessonId : '$lessonId.$extension',
      );
      await source.copy(targetPath);
      return targetPath;
    } on Failure {
      rethrow;
    } catch (error) {
      throw AudioFailure('Не удалось скопировать аудиофайл', cause: error);
    }
  }

  @override
  Future<int> resolveDurationMs(String audioPath) async {
    final player = AudioPlayer();
    try {
      final duration = await player.setFilePath(audioPath);
      if (duration == null || duration.inMilliseconds <= 0) {
        throw const AudioFailure('Не удалось определить длительность аудио');
      }
      return duration.inMilliseconds;
    } on Failure {
      rethrow;
    } catch (error) {
      throw AudioFailure('Не удалось прочитать аудиофайл', cause: error);
    } finally {
      await player.dispose();
    }
  }

  @override
  Future<void> deleteAudio(String audioPath) async {
    try {
      final audio = File(audioPath);
      if (await audio.exists()) {
        await audio.delete();
      }
      // `.wave` пишет just_waveform на мобильных, `.peaks` — flutter_soloud
      // на десктопе; какой из них есть, зависит от платформы.
      for (final suffix in const ['.wave', '.peaks']) {
        final cache = File('$audioPath$suffix');
        if (await cache.exists()) {
          await cache.delete();
        }
      }
    } catch (error) {
      throw AudioFailure('Не удалось удалить аудиофайл', cause: error);
    }
  }
}
