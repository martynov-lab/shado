import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/failures.dart';

/// Local audio copies named `<audio_id>.<extension>`.
abstract interface class AudioCache {
  /// Path to the ready file; `null` when it does not exist yet.
  Future<String?> find(String audioId);

  /// Path for this audio file; the directory is created, the file is not.
  Future<String> pathFor(String audioId, String extension);

  /// Puts an already local file into the cache.
  Future<String> put({
    required String audioId,
    required String extension,
    required String sourcePath,
  });

  /// Whether the file checksum matches the server one.
  Future<bool> verify(String path, String sha256);

  Future<void> remove(String audioId);

  /// Removes everything not listed in [audioIds] from the cache.
  Future<void> retainOnly(Set<String> audioIds);

  /// Shrinks the cache to [maxBytes], evicting least recently used files.
  Future<void> trimToSize(int maxBytes);

  /// Wipes the whole cache.
  Future<void> clear();
}

class FileAudioCache implements AudioCache {
  const FileAudioCache();

  static const String _dirName = 'audio';

  /// Cache directory — `ApplicationDocumentsDirectory/audio`.
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
      // Files can be tens of megabytes — hash them as a stream.
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
      // The least recently used files go first.
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

  /// `<audio_id>.mp3` → `audio_id`.
  static String? _audioIdOf(String path) {
    final name = p.basenameWithoutExtension(path);
    return name.isEmpty ? null : name;
  }
}
