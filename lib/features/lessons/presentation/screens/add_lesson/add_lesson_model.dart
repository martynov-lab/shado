import 'package:dio/dio.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/language_providers.dart';
import 'package:shado/di/lesson_providers.dart';

import '../../../../auth/domain/entities/user_session.dart';
import '../../../../auth/domain/services/auth_service.dart';
import '../../../../languages/domain/entities/language.dart';
import '../../../../languages/domain/services/language_service.dart';
import '../../../domain/entities/audio_upload.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_category.dart';
import '../../../domain/entities/tts_quota.dart';
import '../../../domain/lesson_visibility.dart';
import '../../../domain/services/lesson_catalog_service.dart';
import '../../../domain/services/tts_voice_service.dart';
import '../../../domain/usecases/create_lesson.dart';
import '../../../domain/usecases/get_topics.dart';
import '../../../domain/usecases/get_tts_quota.dart';
import '../../../domain/usecases/synthesize_tts.dart';
import '../../../domain/usecases/upload_audio.dart';
import 'add_lesson_form_state.dart';

/// Uploads, voice-overs and lesson creation for the lesson creation screen.
/// One upload or voice-over runs at a time; a new one cancels the previous.
class AddLessonModel extends ElementaryModel {
  AddLessonModel(ProviderContainer container)
    : _auth = container.read(authServiceProvider),
      _languages = container.read(languageServiceProvider),
      _ttsVoices = container.read(ttsVoiceServiceProvider),
      _catalog = container.read(lessonCatalogServiceProvider),
      _uploadAudio = container.read(uploadAudioProvider),
      _synthesizeTts = container.read(synthesizeTtsProvider),
      _createLesson = container.read(createLessonProvider),
      _getTopics = container.read(getTopicsProvider),
      _getQuota = container.read(getTtsQuotaProvider);

  final AuthService _auth;
  final LanguageService _languages;
  final TtsVoiceService _ttsVoices;
  final LessonCatalogService _catalog;
  final UploadAudio _uploadAudio;
  final SynthesizeTts _synthesizeTts;
  final CreateLesson _createLesson;
  final GetTopics _getTopics;
  final GetTtsQuota _getQuota;

  CancelToken? _uploadCancel;

  late final StreamValueNotifier<UserSession> _session = StreamValueNotifier(
    _auth.session,
    _auth.changes,
  );
  late final StreamValueNotifier<List<Accent>> _accents = StreamValueNotifier(
    _languages.currentAccents,
    _languages.currentChanges.map((language) => language?.accents ?? const []),
  );

  /// The owner gets the privacy switch and the AI voice-over.
  ValueListenable<UserSession> get session => _session;

  /// Accents of the studied language; without any the accent isn't asked.
  ValueListenable<List<Accent>> get accents => _accents;

  @override
  void init() {
    super.init();
    _languages.loadForCurrent();
    _ttsVoices.load().ignore();
  }

  AudioPlayer createPreviewPlayer() => AudioPlayer();

  Future<List<Topic>> loadTopics() => _getTopics();

  Future<TtsQuota> loadQuota() => _getQuota();

  /// `null` when a newer upload or voice-over replaced this one.
  Future<AudioUpload?> uploadAudio(
    String path, {
    required void Function(double progress) onProgress,
  }) => _runUpload(
    (cancel) => _uploadAudio(
      filePath: path,
      cancel: cancel,
      onProgress: (sent, total) {
        if (_uploadCancel == cancel && total > 0) onProgress(sent / total);
      },
    ),
  );

  /// Voices [text] with the voice and accent from settings; `null` when a
  /// newer upload or voice-over replaced this one.
  Future<AudioUpload?> synthesize(String text) => _runUpload(
    (cancel) => _synthesizeTts(
      text: text,
      voice: _ttsVoices.selection.voice,
      accent: _ttsVoices.accentForRequest(),
      cancel: cancel,
    ),
  );

  void cancelUpload() {
    _uploadCancel?.cancel();
    _uploadCancel = null;
  }

  /// Creates the lesson and reloads the catalog. A language without accents
  /// sends no accent; the role decides whether the lesson is public.
  Future<Lesson> createLesson(AddLessonFormState form) async {
    final audioId = form.audioId;
    final level = form.level;
    final needsAccent = _accents.value.isNotEmpty;
    final accent = needsAccent ? form.accent : null;
    if (audioId == null || level == null || (needsAccent && accent == null)) {
      throw StateError('The form is not complete');
    }
    final lesson = await _createLesson(
      CreateLessonParams(
        title: form.title,
        rawText: form.text,
        audioId: audioId,
        durationMs: form.durationMs,
        accent: accent,
        level: level,
        topicId: form.topicId,
        boundaries: form.boundaries.isEmpty ? null : form.boundaries,
        isPublic: publicFlagForRole(
          _session.value.user?.role,
          requested: form.isPublic,
        ),
      ),
    );
    _catalog.reload();
    return lesson;
  }

  @override
  void dispose() {
    _uploadCancel?.cancel();
    _session.dispose();
    _accents.dispose();
    super.dispose();
  }

  Future<AudioUpload?> _runUpload(
    Future<AudioUpload> Function(CancelToken cancel) upload,
  ) async {
    _uploadCancel?.cancel();
    final cancel = _uploadCancel = CancelToken();
    try {
      final result = await upload(cancel);
      return _uploadCancel == cancel ? result : null;
    } catch (_) {
      if (_uploadCancel != cancel) return null;
      rethrow;
    } finally {
      if (_uploadCancel == cancel) _uploadCancel = null;
    }
  }
}
