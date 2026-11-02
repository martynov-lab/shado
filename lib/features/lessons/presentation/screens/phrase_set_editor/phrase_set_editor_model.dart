import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';

import 'package:shado/core/audio/clip_player.dart';
import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/translation_providers.dart';

import '../../../../auth/domain/entities/auth_user.dart';
import '../../../../auth/domain/services/auth_service.dart';
import '../../../../languages/domain/entities/language.dart';
import '../../../../languages/domain/services/language_service.dart';
import '../../../../translation/domain/services/phrase_translator.dart';
import '../../../../translation/domain/services/translation_language_service.dart';
import '../../../domain/entities/audio_upload.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_category.dart';
import '../../../domain/entities/tts_quota.dart';
import '../../../domain/services/lesson_catalog_service.dart';
import '../../../domain/services/tts_voice_service.dart';
import '../../../domain/usecases/get_lesson.dart';
import '../../../domain/usecases/get_topics.dart';
import '../../../domain/usecases/get_tts_quota.dart';
import '../../../domain/usecases/save_phrase_set.dart';
import '../../../domain/usecases/synthesize_phrases.dart';

/// Loading, voicing, translating and saving for the phrase set editor.
class PhraseSetEditorModel extends ElementaryModel {
  PhraseSetEditorModel(ProviderContainer container, this.lessonId)
    : _auth = container.read(authServiceProvider),
      _languages = container.read(languageServiceProvider),
      _translationLanguages = container.read(
        translationLanguageServiceProvider,
      ),
      _translator = container.read(phraseTranslatorProvider),
      _ttsVoices = container.read(ttsVoiceServiceProvider),
      _catalog = container.read(lessonCatalogServiceProvider),
      _getLesson = container.read(getLessonProvider),
      _getTopics = container.read(getTopicsProvider),
      _getQuota = container.read(getTtsQuotaProvider),
      _synthesize = container.read(synthesizePhrasesProvider),
      _save = container.read(savePhraseSetProvider);

  /// The set being edited; `null` creates a new one.
  final String? lessonId;

  final AuthService _auth;
  final LanguageService _languages;
  final TranslationLanguageService _translationLanguages;
  final PhraseTranslator _translator;
  final TtsVoiceService _ttsVoices;
  final LessonCatalogService _catalog;
  final GetLesson _getLesson;
  final GetTopics _getTopics;
  final GetTtsQuota _getQuota;
  final SynthesizePhrases _synthesize;
  final SavePhraseSet _save;

  late final StreamValueNotifier<UserRole?> _role = StreamValueNotifier(
    _auth.session.user?.role,
    _auth.changes.map((session) => session.user?.role),
  );
  late final StreamValueNotifier<List<Accent>> _accents = StreamValueNotifier(
    _languages.currentAccents,
    _languages.currentChanges.map((language) => language?.accents ?? const []),
  );
  late final StreamValueNotifier<String> _translationLanguage =
      StreamValueNotifier(
        _translationLanguages.currentCode,
        _translationLanguages.currentChanges,
      );

  ValueListenable<UserRole?> get role => _role;

  /// Accents of the studied language; without any the accent isn't asked.
  ValueListenable<List<Accent>> get accents => _accents;

  /// Code of the language translations are written in.
  ValueListenable<String> get translationLanguage => _translationLanguage;

  /// Name of the translation language for the column hint.
  String translationLanguageLabel(String code) =>
      _translationLanguages.labelFor(code);

  @override
  void init() {
    super.init();
    _languages.loadForCurrent();
    _ttsVoices.load().ignore();
    _translationLanguages.load().ignore();
  }

  /// A fresh id for a new phrase.
  String newPhraseId() => const Uuid().v4();

  ClipPlayer createPreviewPlayer() => ClipPlayer(AudioPlayer());

  Future<Lesson> loadLesson(String id) => _getLesson(id);

  Future<List<Topic>> loadTopics() => _getTopics();

  Future<TtsQuota> loadQuota() => _getQuota();

  /// Voices [texts] with the voice from settings and the set [accent].
  Future<List<AudioUpload>> synthesize(List<String> texts, String? accent) =>
      _synthesize(texts, voice: _ttsVoices.selection.voice, accent: accent);

  /// Machine translation of [texts] from [sourceLang]; an empty code lets
  /// the server take the studied language.
  Future<List<String>> translate(List<String> texts, String sourceLang) =>
      _translator.translateAll(texts, sourceLang: sourceLang);

  /// Code of the studied language, the language of a new set.
  String get studiedLanguage => _languages.currentCode ?? '';

  /// Saves the set and reloads the catalog.
  Future<Lesson> save(PhraseSetForm form, {Lesson? existing}) async {
    final lesson = await _save(form, existing: existing);
    _catalog.reload();
    return lesson;
  }

  @override
  void dispose() {
    _role.dispose();
    _accents.dispose();
    _translationLanguage.dispose();
    super.dispose();
  }
}
