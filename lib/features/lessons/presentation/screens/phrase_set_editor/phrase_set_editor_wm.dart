import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../auth/domain/entities/auth_user.dart';
import '../../../../home/presentation/screens/home_page.dart';
import '../../../../languages/domain/entities/language.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_category.dart';
import '../../../domain/entities/phrase_draft.dart';
import '../../../domain/phrase_text.dart';
import '../../../domain/usecases/save_phrase_set.dart';
import '../../widgets/phrase_text_import_sheet.dart';
import '../../widgets/version_conflict_dialog.dart';
import '../../widgets/voice_one_by_one_dialog.dart';
import '../phrase_set/phrase_set_page.dart';
import 'phrase_set_editor_model.dart';
import 'phrase_set_editor_page.dart';
import 'phrase_set_editor_state.dart';

PhraseSetEditorWidgetModel phraseSetEditorWidgetModelFactory(
  BuildContext context,
) {
  final page = context.widget as PhraseSetEditorPage;
  return PhraseSetEditorWidgetModel(
    PhraseSetEditorModel(
      ProviderScope.containerOf(context, listen: false),
      page.lessonId,
    ),
  );
}

class PhraseSetEditorWidgetModel
    extends WidgetModel<PhraseSetEditorPage, PhraseSetEditorModel> {
  PhraseSetEditorWidgetModel(super.model);

  final TextEditingController titleController = TextEditingController();

  final ValueNotifier<AsyncState<void>> _loading = ValueNotifier(
    const AsyncPending(),
  );
  final ValueNotifier<PhraseSetEditorState> _state = ValueNotifier(
    const PhraseSetEditorState(),
  );
  final ValueNotifier<AsyncState<List<Topic>>> _topics = ValueNotifier(
    const AsyncPending(),
  );
  final ValueNotifier<int?> _quotaLeft = ValueNotifier(null);
  final ValueNotifier<String?> _playingId = ValueNotifier(null);
  late final _preview = model.createPreviewPlayer();
  StreamSubscription<void>? _previewSubscription;

  /// The set being edited; `null` while creating.
  Lesson? _existing;

  /// `null` until an existing set is loaded; ready at once for a new one.
  ValueListenable<AsyncState<void>> get loading => _loading;
  ValueListenable<PhraseSetEditorState> get state => _state;
  ValueListenable<AsyncState<List<Topic>>> get topics => _topics;
  ValueListenable<List<Accent>> get accents => model.accents;
  ValueListenable<UserRole?> get role => model.role;
  ValueListenable<String> get translationLanguage => model.translationLanguage;

  /// Voice-overs left today; `null` hides the hint.
  ValueListenable<int?> get quotaLeft => _quotaLeft;

  /// Phrase whose audio is playing in the editor.
  ValueListenable<String?> get playingId => _playingId;

  bool get isEditing => widget.lessonId != null;

  /// Only authors of public lessons choose the visibility.
  bool get canPublish => model.role.value?.canAuthor ?? false;

  bool get canSave =>
      _state.value.canSave(needsAccent: model.accents.value.isNotEmpty);

  String translationLanguageLabel(String code) =>
      model.translationLanguageLabel(code);

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _previewSubscription = _preview.playingChanges.listen((playing) {
      if (!playing && _playingId.value != null) _playingId.value = null;
    });
    unawaited(_loadTopics());
    unawaited(_loadQuota());
    unawaited(_open());
  }

  @override
  void dispose() {
    unawaited(_previewSubscription?.cancel());
    unawaited(_preview.dispose());
    titleController.dispose();
    _loading.dispose();
    _state.dispose();
    _topics.dispose();
    _quotaLeft.dispose();
    _playingId.dispose();
    super.dispose();
  }

  void back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(HomePage.routePath);
    }
  }

  Future<void> retry() => _open();

  void setTitle(String title) => _update(_state.value.copyWith(title: title));

  void setAccent(String? accent) =>
      _update(_state.value.copyWith(accent: accent));

  void setLevel(LessonLevel? level) =>
      _update(_state.value.copyWith(level: level));

  void setTopic(String? topicId) =>
      _update(_state.value.copyWith(topicId: topicId));

  void setPrivate(bool isPrivate) =>
      _update(_state.value.copyWith(isPublic: !isPrivate));

  void addPhrase() => _update(
    _state.value.copyWith(
      phrases: [
        ..._state.value.phrases,
        PhraseDraft(id: model.newPhraseId()),
      ],
    ),
  );

  /// Pastes a text cut into phrases at dots and translates them. The new
  /// phrases replace empty rows and go to the end of the list.
  Future<void> importText() async {
    if (_state.value.isBusy) return;
    final text = await showAppBottomSheet<String>(
      context: context,
      title: 'Paste text',
      builder: (_) => const PhraseTextImportSheet(),
    );
    if (text == null || !isMounted) return;
    final texts = splitIntoPhrases(text);
    if (texts.isEmpty) {
      _showMessage('No phrases found in the text');
      return;
    }
    final kept = [
      for (final phrase in _state.value.phrases)
        if (phrase.hasText) phrase,
    ];
    final room = kMaxPhrasesInSet - kept.length;
    if (room <= 0) {
      _showMessage('A set holds at most $kMaxPhrasesInSet phrases');
      return;
    }
    if (texts.length > room) {
      _showMessage('Only the first $room phrases fit into the set');
    }
    _update(
      _state.value.copyWith(
        phrases: [
          ...kept,
          for (final text in texts.take(room))
            PhraseDraft(id: model.newPhraseId(), text: text),
        ],
      ),
    );
    await translateAll();
  }

  void removePhrase(String id) => _update(
    _state.value.copyWith(
      phrases: [
        for (final phrase in _state.value.phrases)
          if (phrase.id != id) phrase,
      ],
    ),
  );

  /// Moves a phrase to [newIndex], counted without the moved one.
  void movePhrase(int oldIndex, int newIndex) {
    final phrases = List.of(_state.value.phrases);
    phrases.insert(newIndex, phrases.removeAt(oldIndex));
    _update(_state.value.copyWith(phrases: phrases));
  }

  void setPhraseText(String id, String text) =>
      _update(_state.value.updatePhrase(id, (phrase) => phrase.withText(text)));

  void setPhraseTranslation(String id, String translation) => _update(
    _state.value.updatePhrase(
      id,
      (phrase) =>
          phrase.withTranslation(model.translationLanguage.value, translation),
    ),
  );

  /// Fills in the missing translations; edited ones stay as they are.
  Future<void> translateAll() async {
    final language = model.translationLanguage.value;
    final missing = _state.value.missingTranslations(language);
    if (missing.isEmpty || _state.value.isBusy) return;
    _update(_state.value.copyWith(isTranslating: true));
    try {
      final translations = await model.translate([
        for (final phrase in missing) phrase.trimmedText,
      ], _existing?.language ?? model.studiedLanguage);
      var next = _state.value;
      for (var i = 0; i < missing.length && i < translations.length; i++) {
        next = next.updatePhrase(
          missing[i].id,
          (phrase) => phrase.translationFor(language).trim().isEmpty
              ? phrase.withTranslation(language, translations[i])
              : phrase,
        );
      }
      _update(next);
    } on Failure catch (failure) {
      _showMessage(failure.message);
    } finally {
      _update(_state.value.copyWith(isTranslating: false));
    }
  }

  /// Voices every phrase without up-to-date audio in one batch.
  Future<void> voiceAll() async {
    final pending = _state.value.toVoice;
    if (pending.isEmpty || _state.value.isBusy) return;
    try {
      await _voice(pending);
    } on ApiException catch (error) {
      if (error.code != ApiErrorCode.ttsSplitFailed) {
        _showVoiceError(error);
        return;
      }
      await _offerOneByOne(pending);
    }
  }

  /// Voices one phrase again.
  Future<void> voicePhrase(String id) async {
    final phrase = _phrase(id);
    if (phrase == null || !phrase.hasText || _state.value.isBusy) return;
    try {
      await _voice([phrase]);
    } on ApiException catch (error) {
      _showVoiceError(error);
    }
  }

  /// Plays the audio of a phrase, or stops it when it is already playing.
  Future<void> togglePhrasePlay(String id) async {
    final phrase = _phrase(id);
    if (phrase == null || phrase.audioPath.isEmpty) return;
    if (_playingId.value == id) {
      await _preview.stop();
      _playingId.value = null;
      return;
    }
    try {
      _playingId.value = id;
      await _preview.play(
        phrase.audioPath,
        startMs: phrase.playStartMs,
        endMs: phrase.endMs,
      );
    } catch (error) {
      _playingId.value = null;
      _showMessage('Failed to play the phrase: $error');
    }
  }

  Future<void> save() async {
    if (!canSave) return;
    final context = this.context;
    final current = _state.value;
    _update(current.copyWith(isSaving: true));
    try {
      final lesson = await model.save(
        PhraseSetForm(
          title: current.title,
          phrases: current.phrases,
          level: current.level,
          accent: model.accents.value.isEmpty ? null : current.accent,
          topicId: current.topicId,
          isPublic: canPublish ? current.isPublic : null,
        ),
        existing: _existing,
      );
      if (!context.mounted) return;
      _afterSave(context, lesson);
    } on ApiException catch (error) {
      if (error.isVersionConflict && context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => const VersionConflictDialog(),
        );
        await _open();
      } else {
        _showMessage(error.message);
      }
    } on Failure catch (failure) {
      _showMessage(failure.message);
    } finally {
      if (isMounted) _update(_state.value.copyWith(isSaving: false));
    }
  }

  /// An edit goes back to the cards; a new set opens them and the editor
  /// starts over.
  void _afterSave(BuildContext context, Lesson lesson) {
    if (isEditing) {
      context.pop();
      return;
    }
    titleController.clear();
    unawaited(_open());
    unawaited(context.push(PhraseSetPage.routeTo(lesson.id)));
  }

  Future<void> _voice(List<PhraseDraft> phrases) async {
    _update(_state.value.copyWith(isVoicing: true));
    try {
      final uploads = await model.synthesize([
        for (final phrase in phrases) phrase.trimmedText,
      ], _state.value.accent);
      var next = _state.value;
      for (var i = 0; i < phrases.length && i < uploads.length; i++) {
        final voicedText = phrases[i].trimmedText;
        next = next.updatePhrase(
          phrases[i].id,
          // A text changed during the request keeps waiting for its voice.
          (phrase) => phrase.trimmedText == voicedText
              ? phrase.withAudio(uploads[i])
              : phrase,
        );
      }
      _update(next);
    } on Failure catch (failure) {
      if (failure is ApiException) rethrow;
      _showMessage(failure.message);
    } finally {
      if (isMounted) _update(_state.value.copyWith(isVoicing: false));
      unawaited(_loadQuota());
    }
  }

  Future<void> _offerOneByOne(List<PhraseDraft> pending) async {
    if (!isMounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => VoiceOneByOneDialog(count: pending.length),
    );
    if (confirmed != true) return;
    for (final phrase in pending) {
      try {
        await _voice([phrase]);
      } on ApiException catch (error) {
        _showVoiceError(error);
        return;
      }
    }
  }

  void _showVoiceError(ApiException error) => _showMessage(switch (error.code) {
    ApiErrorCode.ttsSplitFailed =>
      'The AI could not voice this phrase separately — try again',
    ApiErrorCode.ttsUnavailable =>
      'The AI voice-over is unavailable right now — try again later',
    _ => error.message,
  });

  Future<void> _open() async {
    final id = widget.lessonId;
    if (id == null) {
      _update(PhraseSetEditorState(phrases: [PhraseDraft(id: model.newPhraseId())]));
      _loading.value = const AsyncReady(null);
      return;
    }
    _loading.value = const AsyncPending();
    try {
      final lesson = await model.loadLesson(id);
      if (!isMounted) return;
      _existing = lesson;
      titleController.text = lesson.title;
      _update(
        PhraseSetEditorState(
          title: lesson.title,
          accent: lesson.accent,
          level: lesson.level,
          topicId: lesson.topic?.id,
          isPublic: lesson.isPublic,
          phrases: [
            for (final phrase in lesson.phrases) PhraseDraft.fromPhrase(phrase),
          ],
        ),
      );
      _loading.value = const AsyncReady(null);
    } catch (error, stackTrace) {
      if (isMounted) _loading.value = AsyncFailed(error, stackTrace);
    }
  }

  Future<void> _loadTopics() async {
    final topics = await AsyncState.guard(model.loadTopics);
    if (isMounted) _topics.value = topics;
  }

  Future<void> _loadQuota() async {
    try {
      final quota = await model.loadQuota();
      if (isMounted) _quotaLeft.value = quota.remainingToday;
    } catch (_) {
      // Without the quota the hint is simply hidden.
    }
  }

  PhraseDraft? _phrase(String id) {
    for (final phrase in _state.value.phrases) {
      if (phrase.id == id) return phrase;
    }
    return null;
  }

  void _update(PhraseSetEditorState next) {
    if (isMounted) _state.value = next;
  }

  void _showMessage(String message) {
    if (!isMounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
