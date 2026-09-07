import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/network/api_exception.dart';
import 'package:shado/features/auth/domain/entities/auth_user.dart';
import 'package:shado/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shado/features/lessons/domain/entities/lesson.dart';
import 'package:shado/features/lessons/domain/entities/lesson_category.dart';
import 'package:shado/features/lessons/domain/entities/tts_quota.dart';
import 'package:shado/features/lessons/domain/entities/tts_voice.dart';
import 'package:shado/features/lessons/domain/entities/audio_upload.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shado/features/lessons/presentation/controllers/lesson_providers.dart';
import 'package:shado/features/lessons/presentation/controllers/lessons_filter.dart';
import 'package:shado/features/settings/presentation/controllers/studied_language_controller.dart';

/// A profile whose language change either succeeds or fails with the error.
class _FakeAuthController extends AuthController {
  _FakeAuthController({this.error});

  /// Thrown instead of saving the profile; `null` accepts the language.
  final Object? error;

  final List<String?> savedLanguages = [];

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: AuthUser(
      id: 'user-1',
      email: 'user@example.com',
      role: UserRole.user,
      createdAt: DateTime.utc(2026),
      studiedLanguage: 'en',
    ),
  );

  @override
  Future<void> updateProfile({
    String? name,
    String? studiedLanguage,
    int? dailyGoalMinutes,
  }) async {
    if (error != null) throw error!;
    savedLanguages.add(studiedLanguage);
    state = state.copyWith(
      user: AuthUser(
        id: 'user-1',
        email: 'user@example.com',
        role: UserRole.user,
        createdAt: DateTime.utc(2026),
        studiedLanguage: studiedLanguage,
      ),
    );
  }
}

/// Lesson repository remembering whether the cache was wiped.
class _FakeLessonRepository implements LessonRepository {
  bool cleared = false;

  @override
  Future<void> clearCache() async => cleared = true;

  @override
  Future<List<Lesson>> getLessons() async => const [];

  @override
  Future<void> syncLessons({String language = ''}) async {}

  @override
  Future<Lesson?> getLesson(String id) async => null;

  @override
  Future<AudioUpload> uploadAudio({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    Object? cancel,
  }) async => throw UnimplementedError();

  @override
  Future<AudioUpload> synthesizeTts({
    required String text,
    String? voice,
    String? accent,
    Object? cancel,
  }) async => throw UnimplementedError();

  @override
  Future<TtsVoices> ttsVoices() async => const TtsVoices();

  @override
  Future<TtsPreview> previewTtsVoice({
    required String voice,
    String? accent,
  }) async => const TtsPreview(localPath: '');

  @override
  Future<TtsQuota> ttsQuota() async => throw UnimplementedError();

  @override
  Future<List<Topic>> getTopics() async => const [];

  @override
  Future<Lesson> createLesson({
    required String title,
    required String audioId,
    required int durationMs,
    required List<String> segmentTexts,
    required String? accent,
    required LessonLevel level,
    String? topicId,
    List<int>? boundaries,
    bool? isPublic,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateLesson(Lesson lesson, {bool? isPublic}) async {}

  @override
  Future<void> deleteLesson(String id) async {}
}

/// CLIENT_LANGUAGES_PLAN §3.4: the order of a language switch.
void main() {
  ({
    ProviderContainer container,
    _FakeAuthController auth,
    _FakeLessonRepository lessons,
  })
  build({Object? profileError}) {
    final auth = _FakeAuthController(error: profileError);
    final lessons = _FakeLessonRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        lessonRepositoryProvider.overrideWithValue(lessons),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, auth: auth, lessons: lessons);
  }

  test('успешная смена сносит кеш и сбрасывает фильтры', () async {
    final env = build();
    env.container.read(lessonsFilterProvider.notifier).toggleAccent('UK');

    final error = await env.container
        .read(studiedLanguageControllerProvider.notifier)
        .change('fr');

    expect(error, isNull);
    expect(env.auth.savedLanguages, ['fr']);
    expect(env.lessons.cleared, isTrue);
    // An accent of the previous language would give a `422` on the catalog.
    expect(env.container.read(lessonsFilterProvider).isEmpty, isTrue);
  });

  test('422 оставляет прежний язык, кеш и фильтры нетронутыми', () async {
    final env = build(
      profileError: const ApiException(
        code: ApiErrorCode.validationError,
        message: 'unknown language',
        status: 422,
      ),
    );
    env.container.read(lessonsFilterProvider.notifier).toggleAccent('UK');

    final error = await env.container
        .read(studiedLanguageControllerProvider.notifier)
        .change('xx');

    expect(error, 'Сервер не принял язык — выберите другой');
    // The catalog is not touched until the profile accepts the language.
    expect(env.lessons.cleared, isFalse);
    expect(env.container.read(lessonsFilterProvider).accents, {'UK'});
    expect(
      env.container.read(authControllerProvider).user?.studiedLanguage,
      'en',
    );
  });
}
