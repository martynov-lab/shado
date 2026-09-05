import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/platform/platform_setup.dart';
import '../../data/datasources/audio_cache.dart';
import '../../data/datasources/audio_remote_datasource.dart';
import '../../data/datasources/lesson_local_datasource.dart';
import '../../data/datasources/lesson_local_datasource_sqflite.dart';
import '../../data/datasources/lesson_remote_datasource.dart';
import '../../data/datasources/topic_remote_datasource.dart';
import '../../data/datasources/tts_remote_datasource.dart';
import '../../data/datasources/waveform_datasource.dart';
import '../../data/datasources/waveform_datasource_remote.dart';
import '../../data/datasources/waveform_datasource_soloud.dart';
import '../../data/repositories/lesson_repository_impl.dart';
import '../../domain/entities/lesson_category.dart';
import '../../domain/entities/tts_quota.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/delete_lesson.dart';
import '../../domain/usecases/get_lesson.dart';
import '../../domain/usecases/get_lessons.dart';
import '../../domain/usecases/get_topics.dart';
import '../../domain/usecases/get_tts_quota.dart';
import '../../domain/usecases/synthesize_tts.dart';
import '../../domain/usecases/sync_lessons.dart';
import '../../domain/usecases/update_lesson_content.dart';
import '../../domain/usecases/upload_audio.dart';

/// Dependency wiring for the lessons feature.
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

final ttsRemoteDataSourceProvider = Provider<TtsRemoteDataSource>(
  (ref) => ApiTtsRemoteDataSource(ref.watch(apiClientProvider)),
);

final audioCacheProvider = Provider<AudioCache>(
  (ref) => const FileAudioCache(),
);

/// Waveform peaks source: the server, with a local fallback when offline.
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
    ttsDataSource: ref.watch(ttsRemoteDataSourceProvider),
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

final synthesizeTtsProvider = Provider<SynthesizeTts>(
  (ref) => SynthesizeTts(ref.watch(lessonRepositoryProvider)),
);

final getTtsQuotaProvider = Provider<GetTtsQuota>(
  (ref) => GetTtsQuota(ref.watch(lessonRepositoryProvider)),
);

/// Remaining free voice-overs shown next to the AI voice-over button.
final ttsQuotaProvider = FutureProvider.autoDispose<TtsQuota>(
  (ref) => ref.watch(getTtsQuotaProvider)(),
);

final getTopicsProvider = Provider<GetTopics>(
  (ref) => GetTopics(ref.watch(lessonRepositoryProvider)),
);

/// Topic directory for the dropdown.
final topicsProvider = FutureProvider.autoDispose<List<Topic>>(
  (ref) => ref.watch(getTopicsProvider)(),
);
