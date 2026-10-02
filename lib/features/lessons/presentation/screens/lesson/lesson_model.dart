import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:shado/core/audio/shadowing_audio_handler.dart';
import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/core_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/di/settings_providers.dart';

import '../../../../auth/domain/entities/auth_user.dart';
import '../../../../auth/domain/services/auth_service.dart';
import '../../../../progress/domain/services/progress_reporter.dart';
import '../../../../settings/domain/services/completion_threshold_service.dart';
import '../../../../settings/domain/services/playback_settings_service.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/usecases/get_lesson.dart';
import 'lesson_playback.dart';
import 'lesson_state.dart';

/// The lesson, the role for the edit button and everything the player needs.
class LessonModel extends ElementaryModel {
  LessonModel(ProviderContainer container, this.lessonId)
    : _auth = container.read(authServiceProvider),
      _getLesson = container.read(getLessonProvider),
      _reporter = container.read(progressReporterProvider),
      _settings = container.read(playbackSettingsServiceProvider),
      _threshold = container.read(completionThresholdServiceProvider),
      _audioHandler = container.read(audioHandlerProvider);

  final String lessonId;
  final AuthService _auth;
  final GetLesson _getLesson;
  final ProgressReporter _reporter;
  final PlaybackSettingsService _settings;
  final CompletionThresholdService _threshold;
  final ShadowingAudioHandler? _audioHandler;

  late final StreamValueNotifier<UserRole?> _role = StreamValueNotifier(
    _auth.session.user?.role,
    _auth.changes.map((session) => session.user?.role),
  );

  ValueListenable<UserRole?> get role => _role;

  Future<Lesson> loadLesson() => _getLesson(lessonId);

  /// A player for this screen; the caller disposes it.
  LessonPlayback createPlayback({
    required void Function(LessonState state) onChanged,
    required void Function(int positionMs) onPosition,
  }) => LessonPlayback(
    lessonId: lessonId,
    player: AudioPlayer(),
    reporter: _reporter,
    settings: _settings,
    threshold: _threshold,
    audioHandler: _audioHandler,
    onChanged: onChanged,
    onPosition: onPosition,
  );

  @override
  void dispose() {
    _role.dispose();
    super.dispose();
  }
}
