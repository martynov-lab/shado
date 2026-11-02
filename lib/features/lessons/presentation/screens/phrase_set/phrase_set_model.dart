import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:shado/core/audio/clip_player.dart';
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
import '../../../../translation/domain/services/translation_language_service.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_download.dart';
import '../../../domain/entities/phrase.dart';
import '../../../domain/services/lesson_download_service.dart';
import '../../../domain/usecases/get_lesson.dart';
import 'phrase_set_playback.dart';
import 'phrase_set_state.dart';

/// The phrase set, the role for the edit button, ratings, translations and
/// everything the player needs.
class PhraseSetModel extends ElementaryModel {
  PhraseSetModel(ProviderContainer container, this.lessonId)
    : _auth = container.read(authServiceProvider),
      _getLesson = container.read(getLessonProvider),
      _reporter = container.read(progressReporterProvider),
      _settings = container.read(playbackSettingsServiceProvider),
      _audioHandler = container.read(audioHandlerProvider),
      _downloadService = container.read(lessonDownloadServiceProvider),
      _network = container.read(networkStatusProvider),
      _ratings = container.read(ratingServiceProvider),
      _translator = container.read(phraseTranslatorProvider),
      _translationLanguages = container.read(
        translationLanguageServiceProvider,
      );

  final String lessonId;
  final AuthService _auth;
  final GetLesson _getLesson;
  final ProgressReporter _reporter;
  final PlaybackSettingsService _settings;
  final ShadowingAudioHandler? _audioHandler;
  final LessonDownloadService _downloadService;
  final NetworkStatus _network;
  final RatingService _ratings;
  final PhraseTranslator _translator;
  final TranslationLanguageService _translationLanguages;

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
  late final StreamValueNotifier<String> _translationLanguage =
      StreamValueNotifier(
        _translationLanguages.currentCode,
        _translationLanguages.currentChanges,
      );

  ValueListenable<UserRole?> get role => _role;

  ValueListenable<bool> get isOnline => _isOnline;

  /// Whether this set is kept on the device for offline study.
  ValueListenable<LessonDownload> get download => _download;

  /// Code of the language the card is translated into.
  ValueListenable<String> get translationLanguage => _translationLanguage;

  /// Fires when the ratings of this set change here or on another device.
  Stream<String> get ratingChanges =>
      _ratings.changes.where((id) => id == lessonId);

  @override
  void init() {
    super.init();
    _downloadService.load().ignore();
    _translationLanguages.load().ignore();
  }

  Future<Lesson> loadLesson() => _getLesson(lessonId);

  /// Ratings of the phrases: `itemKey → stars`.
  Future<Map<String, int>> loadStars() => _ratings.starsOf(lessonId);

  /// Gives [stars] to one phrase of [lesson].
  Future<void> rate(String itemKey, int stars, Lesson lesson) => _ratings.rate(
    lessonId: lessonId,
    itemKeys: [itemKey],
    stars: stars,
    lessonItemKeys: lesson.itemKeys,
  );

  /// Machine translations of the phrases without one from the author, by
  /// phrase id; the server caches them, so a repeat costs nothing.
  Future<Map<String, String>> translateMissing(
    Lesson lesson,
    String language,
  ) async {
    final missing = <Phrase>[
      for (final phrase in lesson.phrases)
        if (phrase.translationFor(language) == null) phrase,
    ];
    if (missing.isEmpty || _translator.isSameLanguage(lesson.language)) {
      return const {};
    }
    final translated = await _translator.translateAll([
      for (final phrase in missing) phrase.text,
    ], sourceLang: lesson.language);
    return {
      for (var i = 0; i < missing.length && i < translated.length; i++)
        missing[i].id: translated[i],
    };
  }

  /// Whether the translation language equals the language of [lesson].
  bool isTranslationPointless(Lesson lesson) =>
      _translator.isSameLanguage(lesson.language);

  /// Downloads the set, or removes the download of a downloaded one.
  Future<void> toggleDownload() => switch (_download.value) {
    NotDownloaded() => _downloadService.download(lessonId),
    Downloaded() => _downloadService.remove(lessonId),
    Downloading() => Future.value(),
  };

  /// A player for this screen; the caller disposes it.
  PhraseSetPlayback createPlayback({
    required void Function(PhraseSetState state) onChanged,
  }) => PhraseSetPlayback(
    lessonId: lessonId,
    player: ClipPlayer(AudioPlayer()),
    reporter: _reporter,
    settings: _settings,
    audioHandler: _audioHandler,
    onChanged: onChanged,
  );

  @override
  void dispose() {
    _role.dispose();
    _download.dispose();
    _isOnline.dispose();
    _translationLanguage.dispose();
    super.dispose();
  }
}
