import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/audio_file_datasource.dart';
import '../../data/datasources/lesson_local_datasource.dart';
import '../../data/datasources/lesson_local_datasource_sqflite.dart';
import '../../data/datasources/waveform_datasource.dart';
import '../../data/repositories/lesson_repository_impl.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/delete_lesson.dart';
import '../../domain/usecases/get_lesson.dart';
import '../../domain/usecases/get_lessons.dart';
import '../../domain/usecases/update_segment_boundaries.dart';

/// Сборка зависимостей фичи. Presentation дальше видит только use case'ы.
final lessonLocalDataSourceProvider = Provider<LessonLocalDataSource>(
  (ref) => SqfliteLessonLocalDataSource(),
);

final audioFileDataSourceProvider = Provider<AudioFileDataSource>(
  (ref) => const LocalAudioFileDataSource(),
);

final waveformDataSourceProvider = Provider<WaveformDataSource>(
  (ref) => const JustWaveformDataSource(),
);

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepositoryImpl(
    localDataSource: ref.watch(lessonLocalDataSourceProvider),
    audioDataSource: ref.watch(audioFileDataSourceProvider),
  ),
);

final getLessonsProvider = Provider<GetLessons>(
  (ref) => GetLessons(ref.watch(lessonRepositoryProvider)),
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

final updateSegmentBoundariesProvider = Provider<UpdateSegmentBoundaries>(
  (ref) => UpdateSegmentBoundaries(ref.watch(lessonRepositoryProvider)),
);
