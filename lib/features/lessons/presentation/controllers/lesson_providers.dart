import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/platform/platform_setup.dart';
import '../../data/datasources/audio_cache.dart';
import '../../data/datasources/audio_remote_datasource.dart';
import '../../data/datasources/lesson_local_datasource.dart';
import '../../data/datasources/lesson_local_datasource_sqflite.dart';
import '../../data/datasources/lesson_remote_datasource.dart';
import '../../data/datasources/topic_remote_datasource.dart';
import '../../data/datasources/waveform_datasource.dart';
import '../../data/datasources/waveform_datasource_remote.dart';
import '../../data/datasources/waveform_datasource_soloud.dart';
import '../../data/repositories/lesson_repository_impl.dart';
import '../../domain/entities/lesson_category.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/delete_lesson.dart';
import '../../domain/usecases/get_lesson.dart';
import '../../domain/usecases/get_lessons.dart';
import '../../domain/usecases/get_topics.dart';
import '../../domain/usecases/sync_lessons.dart';
import '../../domain/usecases/update_lesson_content.dart';
import '../../domain/usecases/upload_audio.dart';

/// Сборка зависимостей фичи. Presentation дальше видит только use case'ы.
final lessonLocalDataSourceProvider = Provider<LessonLocalDataSource>(
  (ref) => SqfliteLessonLocalDataSource(),
);

final lessonRemoteDataSourceProvider = Provider<LessonRemoteDataSource>(
  (ref) => ApiLessonRemoteDataSource(ref.watch(apiClientProvider)),
);

final audioRemoteDataSourceProvider = Provider<AudioRemoteDataSource>(
  (ref) => ApiAudioRemoteDataSource(ref.watch(apiClientProvider)),
);

final topicRemoteDataSourceProvider = Provider<TopicRemoteDataSource>(
  (ref) => ApiTopicRemoteDataSource(ref.watch(apiClientProvider)),
);

final audioCacheProvider = Provider<AudioCache>((ref) => const FileAudioCache());

/// Пики считает сервер — волна выходит одинаковой на всех платформах.
///
/// Локальный источник остаётся запасным путём для офлайна: без сети урок с уже
/// скачанным аудио всё равно открывается. На Windows/Linux этим запасным
/// путём работает `flutter_soloud`, на мобильных — `just_waveform`.
final waveformDataSourceProvider = Provider<WaveformDataSource>(
  (ref) => RemoteWaveformDataSource(
    ref.watch(audioRemoteDataSourceProvider),
    fallback: isPluginlessDesktop
        ? const SoLoudWaveformDataSource()
        : const JustWaveformDataSource(),
  ),
);

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepositoryImpl(
    localDataSource: ref.watch(lessonLocalDataSourceProvider),
    remoteDataSource: ref.watch(lessonRemoteDataSourceProvider),
    audioDataSource: ref.watch(audioRemoteDataSourceProvider),
    topicDataSource: ref.watch(topicRemoteDataSourceProvider),
    audioCache: ref.watch(audioCacheProvider),
  ),
);

final getLessonsProvider = Provider<GetLessons>(
  (ref) => GetLessons(ref.watch(lessonRepositoryProvider)),
);

final syncLessonsProvider = Provider<SyncLessons>(
  (ref) => SyncLessons(ref.watch(lessonRepositoryProvider)),
);

final getLessonProvider = Provider<GetLesson>(
  (ref) => GetLesson(ref.watch(lessonRepositoryProvider)),
);

final createLessonProvider = Provider<CreateLesson>(
  (ref) => CreateLesson(ref.watch(lessonRepositoryProvider)),
);

final deleteLessonProvider = Provider<DeleteLesson>(
  (ref) => DeleteLesson(ref.watch(lessonRepositoryProvider)),
);

final updateLessonContentProvider = Provider<UpdateLessonContent>(
  (ref) => UpdateLessonContent(ref.watch(lessonRepositoryProvider)),
);

final uploadAudioProvider = Provider<UploadAudio>(
  (ref) => UploadAudio(ref.watch(lessonRepositoryProvider)),
);

final getTopicsProvider = Provider<GetTopics>(
  (ref) => GetTopics(ref.watch(lessonRepositoryProvider)),
);

/// Справочник тем для выпадающего списка.
///
/// `autoDispose`: список перезапрашивается при каждом входе на экран создания —
/// тему могли переименовать или удалить (§6).
final topicsProvider = FutureProvider.autoDispose<List<Topic>>(
  (ref) => ref.watch(getTopicsProvider)(),
);
