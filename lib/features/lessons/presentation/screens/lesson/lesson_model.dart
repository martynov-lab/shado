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
import 'package:shado/di/translation_providers.dart';

import '../../../../auth/domain/entities/auth_user.dart';
import '../../../../auth/domain/services/auth_service.dart';
import '../../../../progress/domain/services/progress_reporter.dart';
import '../../../../progress/domain/services/rating_service.dart';
import '../../../../settings/domain/services/playback_settings_service.dart';
import '../../../../translation/domain/services/phrase_translator.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_download.dart';
import '../../../domain/entities/segment_range.dart';
import '../../../domain/lesson_permissions.dart';
import '../../../domain/services/lesson_catalog_service.dart';
import '../../../domain/usecases/add_phrase_from_story.dart';
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
      _audioHandler = container.read(audioHandlerProvider),
      _downloadService = container.read(lessonDownloadServiceProvider),
      _network = container.read(networkStatusProvider),
      _translator = container.read(phraseTranslatorProvider),
      _ratings = container.read(ratingServiceProvider),
      _catalog = container.read(lessonCatalogServiceProvider),
      _addPhrase = container.read(addPhraseFromStoryProvider);

  final String lessonId;
  final AuthService _auth;
  final GetLesson _getLesson;
  final ProgressReporter _reporter;
  final PlaybackSettingsService _settings;
  final ShadowingAudioHandler? _audioHandler;
  final LessonDownloadService _downloadService;
  final NetworkStatus _network;
  final PhraseTranslator _translator;
  final RatingService _ratings;
  final LessonCatalogService _catalog;
  final AddPhraseFromStory _addPhrase;

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

  /// Fires when the ratings of this lesson change here or on another device.
  Stream<String> get ratingChanges =>
      _ratings.changes.where((id) => id == lessonId);

  /// Ratings of the lesson items: `itemKey → stars`.
  Future<Map<String, int>> loadStars() => _ratings.starsOf(lessonId);

  /// Gives [stars] to [itemKeys]; [lesson] tells when it is all learned.
  Future<void> rate(List<String> itemKeys, int stars, Lesson lesson) =>
      _ratings.rate(
        lessonId: lessonId,
        itemKeys: itemKeys,
        stars: stars,
        lessonItemKeys: lesson.itemKeys,
      );

  /// Phrase sets a phrase of [story] may go to: the user's own, and only
  /// private ones for a private story.
  Future<List<Lesson>> phraseSetsFor(Lesson story) async {
    final role = _role.value;
    return [
      for (final lesson in await _catalog.loadLessons())
        if (lesson.isExpressions &&
            canModifyLesson(role, lesson) &&
            (story.isPublic || lesson.isPrivate))
          lesson,
    ];
  }

  /// Adds [range] of [story] to [target], or to a new set; the translation
  /// is filled in when the server can give it.
  Future<Lesson> addToPhraseSet(
    Lesson story,
    SegmentRange range, {
    Lesson? target,
  }) async {
    final text = [
      for (var i = range.start; i <= range.end; i++) story.segments[i].text,
    ].join(' ');
    var translations = const <String, String>{};
    if (!_translator.isSameLanguage(story.language)) {
      try {
        final translation = await _translator.translate(
          text,
          sourceLang: story.language,
        );
        translations = {_translator.targetLanguage: translation};
      } on Exception catch (_) {
        // The phrase is added without a translation; the set fills it later.
      }
    }
    final saved = await _addPhrase(
      story: story,
      range: range,
      target: target,
      translations: translations,
    );
    _catalog.reload();
    return saved;
  }

  /// Whether the translation language equals the lesson [language].
  bool isTranslationPointless(String language) =>
      _translator.isSameLanguage(language);

  String? cachedTranslation(String text, String language) =>
      _translator.cached(text, sourceLang: language);

  Future<String> translate(String text, String language) =>
      _translator.translate(text, sourceLang: language);

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
