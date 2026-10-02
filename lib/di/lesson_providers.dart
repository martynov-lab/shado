import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/platform/platform_setup.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/core_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/library_providers.dart';
import 'package:shado/features/lessons/data/datasources/audio_cache.dart';
import 'package:shado/features/lessons/data/datasources/audio_remote_datasource.dart';
import 'package:shado/features/lessons/data/datasources/lesson_local_datasource.dart';
import 'package:shado/features/lessons/data/datasources/lesson_local_datasource_sqflite.dart';
import 'package:shado/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:shado/features/lessons/data/datasources/topic_remote_datasource.dart';
import 'package:shado/features/lessons/data/datasources/tts_remote_datasource.dart';
import 'package:shado/features/lessons/data/datasources/waveform_datasource.dart';
import 'package:shado/features/lessons/data/datasources/waveform_datasource_remote.dart';
import 'package:shado/features/lessons/data/datasources/waveform_datasource_soloud.dart';
import 'package:shado/features/lessons/data/repositories/lesson_repository_impl.dart';
import 'package:shado/features/lessons/data/repositories/topic_repository_impl.dart';
import 'package:shado/features/lessons/data/repositories/tts_voice_settings_repository_impl.dart';
import 'package:shado/features/lessons/data/repositories/waveform_repository_impl.dart';
import 'package:shado/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shado/features/lessons/domain/repositories/topic_repository.dart';
import 'package:shado/features/lessons/domain/repositories/tts_voice_settings_repository.dart';
import 'package:shado/features/lessons/domain/repositories/waveform_repository.dart';
import 'package:shado/features/lessons/domain/services/lesson_catalog_service.dart';
import 'package:shado/features/lessons/domain/services/lesson_download_service.dart';
import 'package:shado/features/lessons/domain/services/tts_voice_service.dart';
import 'package:shado/features/lessons/domain/usecases/create_lesson.dart';
import 'package:shado/features/lessons/domain/usecases/delete_lesson.dart';
import 'package:shado/features/lessons/domain/usecases/get_lesson.dart';
import 'package:shado/features/lessons/domain/usecases/get_lessons.dart';
import 'package:shado/features/lessons/domain/usecases/get_topics.dart';
import 'package:shado/features/lessons/domain/usecases/get_tts_quota.dart';
import 'package:shado/features/lessons/domain/usecases/get_tts_voices.dart';
import 'package:shado/features/lessons/domain/usecases/preview_tts_voice.dart';
import 'package:shado/features/lessons/domain/usecases/sync_lessons.dart';
import 'package:shado/features/lessons/domain/usecases/synthesize_tts.dart';
import 'package:shado/features/lessons/domain/usecases/update_lesson_content.dart';
import 'package:shado/features/lessons/domain/usecases/upload_audio.dart';

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

final getTtsVoicesProvider = Provider<GetTtsVoices>(
  (ref) => GetTtsVoices(ref.watch(lessonRepositoryProvider)),
);

final previewTtsVoiceProvider = Provider<PreviewTtsVoice>(
  (ref) => PreviewTtsVoice(ref.watch(lessonRepositoryProvider)),
);

final getTopicsProvider = Provider<GetTopics>(
  (ref) => GetTopics(ref.watch(lessonRepositoryProvider)),
);

final topicRepositoryProvider = Provider<TopicRepository>(
  (ref) => TopicRepositoryImpl(ref.watch(topicRemoteDataSourceProvider)),
);

final lessonCatalogServiceProvider = Provider<LessonCatalogService>((ref) {
  final service = LessonCatalogService(
    getLessons: ref.watch(getLessonsProvider),
    syncLessons: ref.watch(syncLessonsProvider),
    deleteLesson: ref.watch(deleteLessonProvider),
    getLibrary: ref.watch(getLibraryProvider),
    auth: ref.watch(authServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final lessonDownloadServiceProvider = Provider<LessonDownloadService>((ref) {
  final service = LessonDownloadService(
    repository: ref.watch(lessonRepositoryProvider),
    catalogChanges: ref.watch(lessonCatalogServiceProvider).lessonChanges,
  );
  ref.onDispose(service.dispose);
  return service;
});

final ttsVoiceSettingsRepositoryProvider = Provider<TtsVoiceSettingsRepository>(
  (ref) => TtsVoiceSettingsRepositoryImpl(),
);

final ttsVoiceServiceProvider = Provider<TtsVoiceService>((ref) {
  final service = TtsVoiceService(
    repository: ref.watch(ttsVoiceSettingsRepositoryProvider),
    languages: ref.watch(languageServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final waveformRepositoryProvider = Provider<WaveformRepository>(
  (ref) => WaveformRepositoryImpl(ref.watch(waveformDataSourceProvider)),
);
