import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/failures.dart';

/// Локальные копии аудио, разложенные по `audio_id`.
///
/// Плеер работает с файлом, а не с сетевым источником: в shadowing куски
/// зацикливаются по две-три секунды, и каждый повтор поверх сети дёргался бы.
/// Поэтому файл скачивается один раз и дальше живёт здесь.
///
/// Имя файла — `<audio_id>.<расширение>`. Содержимое под одним `audio_id` не
/// меняется никогда, так что инвалидация кешу не нужна — только чистка.
abstract interface class AudioCache {
  /// Путь к готовому файлу; `null` — его ещё нет.
  Future<String?> find(String audioId);

  /// Куда класть файл этого аудио. Каталог создаётся, сам файл — нет.
  Future<String> pathFor(String audioId, String extension);

  /// Кладёт в кеш уже имеющийся локальный файл (только что отправленный на
  /// сервер): качать его обратно незачем.
  Future<String> put({
    required String audioId,
    required String extension,
    required String sourcePath,
  });

  /// Совпадает ли контрольная сумма файла с серверной.
  Future<bool> verify(String path, String sha256);

  Future<void> remove(String audioId);

  /// Убирает из кеша всё, на что не ссылается ни один живой урок.
  ///
  /// Один `audio_id` может принадлежать нескольким урокам сразу (сервер
  /// дедуплицирует загрузки по sha256), поэтому удаляем не «аудио удалённого
  /// урока», а то, что не нужно никому.
  Future<void> retainOnly(Set<String> audioIds);

  /// Ужимает кеш до [maxBytes], выбрасывая давно не открывавшиеся файлы.
  Future<void> trimToSize(int maxBytes);

  /// Стирает кеш целиком — при выходе из аккаунта.
  Future<void> clear();
}

class FileAudioCache implements AudioCache {
  const FileAudioCache();

  static const String _dirName = 'audio';

  /// Каталог кеша: `ApplicationDocumentsDirectory/audio` — тот же, где аудио
  /// лежало и до появления сервера.
  static Future<Directory> directory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, _dirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<String?> find(String audioId) async {
    try {
      final dir = await directory();
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        if (_audioIdOf(entity.path) == audioId) return entity.path;
      }
      return null;
    } catch (error) {
      throw AudioFailure('Не удалось прочитать кеш аудио', cause: error);
    }
  }

  @override
  Future<String> pathFor(String audioId, String extension) async {
    final dir = await directory();
    final name = extension.isEmpty ? audioId : '$audioId.$extension';
    return p.join(dir.path, name);
  }

  @override
  Future<String> put({
    required String audioId,
    required String extension,
    required String sourcePath,
  }) async {
    try {
      final target = await pathFor(audioId, extension);
      if (p.equals(sourcePath, target)) return target;
      await File(sourcePath).copy(target);
      return target;
    } catch (error) {
      throw AudioFailure('Не удалось сохранить аудио в кеш', cause: error);
    }
  }

  @override
  Future<bool> verify(String path, String sha256) async {
    if (sha256.isEmpty) return true;
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      // Файл может весить десятки мегабайт — считаем сумму потоком.
      final digest = await sha256Stream(file);
      return digest == sha256.toLowerCase();
    } catch (_) {
      return false;
    }
  }

  static Future<String> sha256Stream(File file) async {
    final digest = await sha256.bind(file.openRead()).single;
    return digest.toString();
  }

  @override
  Future<void> remove(String audioId) async {
    final path = await find(audioId);
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (error) {
      throw AudioFailure('Не удалось удалить аудио из кеша', cause: error);
    }
  }

  @override
  Future<void> retainOnly(Set<String> audioIds) async {
    try {
      final dir = await directory();
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final id = _audioIdOf(entity.path);
        if (id == null || audioIds.contains(id)) continue;
        await entity.delete();
      }
    } catch (error) {
      throw AudioFailure('Не удалось почистить кеш аудио', cause: error);
    }
  }

  @override
  Future<void> trimToSize(int maxBytes) async {
    try {
      final dir = await directory();
      final files = <({File file, DateTime accessed, int size})>[];
      var total = 0;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        total += stat.size;
        files.add((file: entity, accessed: stat.accessed, size: stat.size));
      }
      if (total <= maxBytes) return;
      // Давно не открывавшееся уходит первым: урок, к которому вернутся,
      // докачается при следующем открытии.
      files.sort((a, b) => a.accessed.compareTo(b.accessed));
      for (final entry in files) {
        if (total <= maxBytes) break;
        await entry.file.delete();
        total -= entry.size;
      }
    } catch (error) {
      throw AudioFailure('Не удалось ужать кеш аудио', cause: error);
    }
  }

  @override
  Future<void> clear() => retainOnly(const {});

  /// `<audio_id>.mp3` → `audio_id`. Мусор рядом (кеш волны от локальных
  /// источников) под это имя не подходит и остаётся нетронутым.
  static String? _audioIdOf(String path) {
    final name = p.basenameWithoutExtension(path);
    return name.isEmpty ? null : name;
  }
}
