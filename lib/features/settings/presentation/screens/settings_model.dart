import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/settings_providers.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../../languages/domain/entities/language.dart';
import '../../../languages/domain/services/language_service.dart';
import '../../../lessons/domain/entities/tts_voice_selection.dart';
import '../../../lessons/domain/repositories/lesson_repository.dart';
import '../../../lessons/domain/services/lesson_catalog_service.dart';
import '../../../lessons/domain/services/tts_voice_service.dart';
import '../../domain/entities/playback_settings.dart';
import '../../domain/services/playback_settings_service.dart';

/// Data and actions for the settings screen: the profile, the studied
/// language and playback.
class SettingsModel extends ElementaryModel {
  SettingsModel(ProviderContainer container)
    : _auth = container.read(authServiceProvider),
      _languages = container.read(languageServiceProvider),
      _playback = container.read(playbackSettingsServiceProvider),
      _catalog = container.read(lessonCatalogServiceProvider),
      _lessonRepository = container.read(lessonRepositoryProvider),
      _ttsVoices = container.read(ttsVoiceServiceProvider);

  final AuthService _auth;
  final LanguageService _languages;
  final PlaybackSettingsService _playback;
  final LessonCatalogService _catalog;
  final LessonRepository _lessonRepository;
  final TtsVoiceService _ttsVoices;

  late final StreamValueNotifier<AuthUser?> _user = StreamValueNotifier(
    _auth.session.user,
    _auth.changes.map((session) => session.user),
  );
  late final StreamValueNotifier<bool> _isOwner = StreamValueNotifier(
    _auth.session.isOwner,
    _auth.changes.map((session) => session.isOwner),
  );
  late final StreamValueNotifier<Language?> _studiedLanguage =
      StreamValueNotifier(_languages.current, _languages.currentChanges);
  late final StreamValueNotifier<TtsVoiceSelection> _ttsVoice =
      StreamValueNotifier(_ttsVoices.selection, _ttsVoices.changes);
  late final StreamValueNotifier<PlaybackSettings> _playbackSettings =
      StreamValueNotifier(_playback.settings, _playback.changes);

  ValueListenable<AuthUser?> get user => _user;
  ValueListenable<bool> get isOwner => _isOwner;

  /// `null` while the directory loads or when the profile code isn't in it.
  ValueListenable<Language?> get studiedLanguage => _studiedLanguage;

  ValueListenable<TtsVoiceSelection> get ttsVoice => _ttsVoice;

  /// Default values until the saved settings are loaded.
  ValueListenable<PlaybackSettings> get playbackSettings => _playbackSettings;

  @override
  void init() {
    super.init();
    _playback.load().ignore();
    _languages.loadForCurrent();
    _ttsVoices.load().ignore();
  }

  Future<List<Language>> loadLanguages() => _languages.load();

  /// Falls back to the code if the language isn't in the directory.
  String languageLabel(String code) => _languages.labelFor(code);

  Future<void> updateProfile({String? name, int? dailyGoalMinutes}) =>
      _auth.updateProfile(name: name, dailyGoalMinutes: dailyGoalMinutes);

  /// Saves the new language, wipes the lesson cache and reloads the catalog.
  /// The order matters: the old catalog must not mix into the new one.
  Future<void> changeStudiedLanguage(String code) async {
    await _auth.updateProfile(studiedLanguage: code);
    await _lessonRepository.clearCache();
    _catalog.reset();
  }

  Future<void> setDefaultSpeed(double speed) =>
      _playback.setDefaultSpeed(speed);

  Future<void> setRepeatsInCycle(int repeats) =>
      _playback.setRepeatsInCycle(repeats);

  Future<void> setPauseBetweenRepeats(bool enabled) =>
      _playback.setPauseBetweenRepeats(enabled);

  Future<void> setCountdownEnabled(bool enabled) =>
      _playback.setCountdownEnabled(enabled);

  @override
  void dispose() {
    _user.dispose();
    _isOwner.dispose();
    _studiedLanguage.dispose();
    _playbackSettings.dispose();
    _ttsVoice.dispose();
    super.dispose();
  }
}
