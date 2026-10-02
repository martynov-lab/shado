import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:shado/core/audio/shadowing_audio_handler.dart';
import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/core/network/network_status.dart';
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
import '../../../domain/entities/lesson_download.dart';
import '../../../domain/services/lesson_download_service.dart';
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
      _audioHandler = container.read(audioHandlerProvider),
      _downloadService = container.read(lessonDownloadServiceProvider),
      _network = container.read(networkStatusProvider);

  final String lessonId;
  final AuthService _auth;
  final GetLesson _getLesson;
  final ProgressReporter _reporter;
  final PlaybackSettingsService _settings;
  final CompletionThresholdService _threshold;
  final ShadowingAudioHandler? _audioHandler;
  final LessonDownloadService _downloadService;
  final NetworkStatus _network;

  late final StreamValueNotifier<UserRole?> _role = StreamValueNotifier(
    _auth.session.user?.role,
    _auth.changes.map((session) => session.user?.role),
  );

  late final StreamValueNotifier<LessonDownload> _download =
      StreamValueNotifier(
        _downloadService.stateOf(lessonId),
        _downloadService.changes.map((_) => _downloadService.stateOf(lessonId)),
      );

  late final StreamValueNotifier<bool> _isOnline = StreamValueNotifier(
    _network.isOnline,
    _network.changes,
  );

  ValueListenable<UserRole?> get role => _role;

  ValueListenable<bool> get isOnline => _isOnline;

  /// Whether this lesson is kept on the device for offline study.
  ValueListenable<LessonDownload> get download => _download;

  @override
  void init() {
    super.init();
    _downloadService.load().ignore();
  }

  Future<Lesson> loadLesson() => _getLesson(lessonId);

  /// Downloads the lesson, or removes the download of a downloaded one.
  Future<void> toggleDownload() => switch (_download.value) {
    NotDownloaded() => _downloadService.download(lessonId),
    Downloaded() => _downloadService.remove(lessonId),
    Downloading() => Future.value(),
  };

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
    _download.dispose();
    _isOnline.dispose();
    super.dispose();
  }
}
