// End-to-end contract check against a live server; run by hand with
// `flutter test test/live/live_contract.dart`.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shado/core/network/api_client.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shado/features/lessons/data/datasources/audio_remote_datasource.dart';
import 'package:shado/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:shado/core/storage/token_storage.dart';
import 'package:shado/features/lessons/data/models/segment_model.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:uuid/uuid.dart';

/// In-memory tokens: the keychain is irrelevant to the contract check.
class MemoryTokenStorage implements TokenStorage {
  String? _access;
  String? _refresh;

  @override
  String? get accessToken => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> save(AuthTokens tokens) async {
    _access = tokens.accessToken;
    _refresh = tokens.refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

File writeTestWav(String path, {int seconds = 3}) {
  const sampleRate = 44100;
  final frames = sampleRate * seconds;
  final data = ByteData(44 + frames * 2);
  void ascii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + frames * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, frames * 2, Endian.little);
  for (var i = 0; i < frames; i++) {
    final gain = i < frames ~/ 2 ? 0.9 : 0.2;
    final value = math.sin(2 * math.pi * 440 * i / sampleRate) * gain * 32767;
    data.setInt16(44 + i * 2, value.round(), Endian.little);
  }
  return File(path)..writeAsBytesSync(data.buffer.asUint8List());
}

void main() {
  const baseUrl = 'http://127.0.0.1:8080';
  final tokens = MemoryTokenStorage();
  final client = ApiClient(tokens: tokens, baseUrl: baseUrl);
  final auth = ApiAuthRemoteDataSource(client);
  final audioApi = ApiAudioRemoteDataSource(client);
  final lessonApi = ApiLessonRemoteDataSource(client);

  late Directory tempDir;
  late String wavPath;
  late String audioId;
  late int durationMs;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('shado_live');
    wavPath = p.join(tempDir.path, 'tone.wav');
    writeTestWav(wavPath);

    final email = 'live-${const Uuid().v4()}@example.com';
    final session = await auth.register(email: email, password: 'password123');
    await tokens.save(session.tokens);
  });

  tearDownAll(() => tempDir.deleteSync(recursive: true));

  test('audio upload: the server computes the duration and the peaks', () async {
    final uploaded = await audioApi.upload(filePath: wavPath);
    audioId = uploaded.id;
    durationMs = uploaded.durationMs;

    expect(durationMs, closeTo(3000, 150));
    expect(uploaded.sha256, isNotEmpty);
    expect(uploaded.peaks, isNotNull);
    expect(uploaded.peaks!.length, greaterThan(100));
    expect(uploaded.peaks!.maxima.every((v) => v >= 0 && v <= 1), isTrue);
    expect(uploaded.peaks!.minima.every((v) => v <= 0 && v >= -1.01), isTrue);
    expect(uploaded.fileExtension, 'wav');
  });

  test('re-uploading the same file is deduplicated', () async {
    final again = await audioApi.upload(filePath: wavPath);
    expect(again.id, audioId);
  });

  test('peaks come back at the requested resolution', () async {
    final peaks = await audioApi.peaks(audioId, resolution: 500);
    expect(peaks.length, 500);
    expect(peaks.minima.length, peaks.maxima.length);
  });

  test('the file downloads and matches the original', () async {
    final target = p.join(tempDir.path, 'downloaded.wav');
    await audioApi.download(audioId: audioId, targetPath: target);

    expect(File(target).lengthSync(), File(wavPath).lengthSync());
  });

  group('lessons', () {
    final lessonId = const Uuid().v4();

    test('creation in a single PUT', () async {
      final created = await lessonApi.putLesson(
        id: lessonId,
        title: 'Live lesson',
        audioId: audioId,
        createdAt: DateTime.now().toUtc(),
        accent: 'US',
        level: LessonLevel.b1,
        segments: [
          SegmentModel(
            index: 0,
            text: 'One',
            startMs: 0,
            endMs: durationMs ~/ 2,
          ),
          SegmentModel(
            index: 1,
            text: 'Two',
            startMs: durationMs ~/ 2,
            endMs: durationMs,
          ),
        ],
      );

      expect(created.id, lessonId);
      expect(created.version, 1);
      expect(created.segments, hasLength(2));
      expect(created.audio.id, audioId);
      expect(created.accent, 'US');
      expect(created.level, LessonLevel.b1);
      // No topic was passed, so the server must supply its own.
      expect(created.topic, isNotNull);
    });

    test('repeating the same PUT creates no duplicate', () async {
      final page = await lessonApi.list();
      expect(page.items.where((item) => item.id == lessonId), hasLength(1));
    });

    test('an edit without If-Match gives a version conflict with the current lesson', () async {
      try {
        await lessonApi.putLesson(
          id: lessonId,
          title: 'No version',
          audioId: audioId,
          createdAt: DateTime.now().toUtc(),
          // Checks the rejection caused by a missing `If-Match`.
          accent: 'US',
          level: LessonLevel.b1,
          segments: [
            SegmentModel(index: 0, text: 'One', startMs: 0, endMs: durationMs),
          ],
        );
        fail('expected a version conflict');
      } on ApiException catch (error) {
        expect(error.isVersionConflict, isTrue);
        expect(error.current?['version'], 1);
      }
    });

    test('an edit with If-Match raises the version', () async {
      final updated = await lessonApi.putLesson(
        id: lessonId,
        title: 'Edited lesson',
        audioId: audioId,
        createdAt: DateTime.now().toUtc(),
        // `PUT` replaces the whole lesson: categories are resent on edits too.
        accent: 'UK',
        level: LessonLevel.c1,
        segments: [
          SegmentModel(index: 0, text: 'Single', startMs: 0, endMs: durationMs),
        ],
        version: 1,
      );

      expect(updated.version, 2);
      expect(updated.title, 'Edited lesson');
      expect(updated.segments, hasLength(1));
      expect(updated.accent, 'UK');
      expect(updated.level, LessonLevel.c1);
    });

    test('segments that are not back to back give a 422 with an explanation', () async {
      try {
        await lessonApi.putLesson(
          id: lessonId,
          title: 'Gapped',
          audioId: audioId,
          createdAt: DateTime.now().toUtc(),
          segments: [
            SegmentModel(index: 0, text: 'One', startMs: 500, endMs: durationMs),
          ],
          version: 2,
        );
        fail('expected a validation error');
      } on ApiException catch (error) {
        expect(error.code, ApiErrorCode.validationError);
        expect(error.status, 422);
        expect(error.message, isNotEmpty);
      }
    });

    test('the deletion is soft and shows up in the delta', () async {
      final before = await lessonApi.getLesson(lessonId);
      await lessonApi.deleteLesson(lessonId);

      // Without since a deleted lesson is absent from the list.
      final live = await lessonApi.list();
      expect(live.items.where((item) => item.id == lessonId), isEmpty);

      // With since it arrives with a non-empty deleted_at so it vanishes here.
      final delta = await lessonApi.list(
        since: before.updatedAt.toIso8601String(),
      );
      final deleted = delta.items.firstWhere((item) => item.id == lessonId);
      expect(deleted.isDeleted, isTrue);
      expect(deleted.version, greaterThan(before.version));
    });

    test('someone else lesson or a missing one gives a 404', () async {
      try {
        await lessonApi.getLesson(const Uuid().v4());
        fail('expected a 404');
      } on ApiException catch (error) {
        expect(error.isNotFound, isTrue);
      }
    });
  });

  test('a plain user has no access to the admin area', () async {
    try {
      await client.get('/v1/admin/users');
      fail('expected a 403');
    } on ApiException catch (error) {
      expect(error.code, ApiErrorCode.forbidden);
      expect(error.status, 403);
    }
  });

  test('a wrong password gives invalid_credentials', () async {
    final anonymous = ApiClient(tokens: MemoryTokenStorage(), baseUrl: baseUrl);
    try {
      await ApiAuthRemoteDataSource(
        anonymous,
      ).login(email: 'nobody@example.com', password: 'wrong-password');
      fail('expected a rejection');
    } on ApiException catch (error) {
      expect(error.code, ApiErrorCode.invalidCredentials);
    }
  });

  test('access is refreshed and the old refresh token is retired', () async {
    final before = await tokens.readRefreshToken();
    final refreshed = await auth.refresh(before!);
    await tokens.save(refreshed);

    expect(refreshed.accessToken, isNotEmpty);
    expect(refreshed.refreshToken, isNot(before));
    expect(await auth.me(), isNotNull);
  });

  test('a file over the limit is not sent', () async {
    final big = File(p.join(tempDir.path, 'big.wav'));
    big.writeAsBytesSync(Uint8List(51 * 1024 * 1024));
    try {
      await audioApi.upload(filePath: big.path);
      fail('expected a rejection by size');
    } on ApiException catch (error) {
      expect(error.code, ApiErrorCode.payloadTooLarge);
    } finally {
      big.deleteSync();
    }
  });

  test('an upload can be cancelled mid-flight', () async {
    final cancelToken = CancelToken();
    final future = audioApi.upload(
      filePath: wavPath,
      cancelToken: cancelToken,
      onProgress: (sent, total) => cancelToken.cancel(),
    );

    await expectLater(future, throwsA(isA<Object>()));
  });
}
