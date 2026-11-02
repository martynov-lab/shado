import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../progress/domain/item_keys.dart';
import '../../../../settings/presentation/widgets/playback_speed_sheet.dart';
import '../../../domain/entities/lesson_download.dart';
import '../../../domain/entities/phrase.dart';
import '../../../domain/lesson_permissions.dart';
import '../../../domain/phrase_deck.dart';
import '../../widgets/phrase_select_panel.dart';
import 'phrase_set_model.dart';
import 'phrase_set_page.dart';
import 'phrase_set_playback.dart';
import 'phrase_set_state.dart';
import 'phrase_study_mode.dart';

/// What the card shows: the main text, a smaller one and a muted note.
typedef PhraseCardFace = ({String text, String? secondary, String? hint});

PhraseSetWidgetModel phraseSetWidgetModelFactory(BuildContext context) {
  final page = context.widget as PhraseSetPage;
  return PhraseSetWidgetModel(
    PhraseSetModel(ProviderScope.containerOf(context, listen: false), page.lessonId),
  );
}

class PhraseSetWidgetModel extends WidgetModel<PhraseSetPage, PhraseSetModel> {
  PhraseSetWidgetModel(super.model);

  /// While the screen holds the focus, arrows, space and digits work.
  final FocusNode pageFocus = FocusNode(debugLabel: 'phrase-set-page');

  final ValueNotifier<AsyncState<PhraseSetState>> _state = ValueNotifier(
    const AsyncPending(),
  );
  final ValueNotifier<Map<String, int>> _stars = ValueNotifier(const {});
  final ValueNotifier<Map<String, String>> _machineTranslations = ValueNotifier(
    const {},
  );
  late final ValueNotifier<bool> _canEdit = ValueNotifier(_currentCanEdit());
  late final Listenable _editSources = Listenable.merge([
    _state,
    model.role,
    model.isOnline,
  ]);
  late final PhraseSetPlayback _playback = model.createPlayback(
    onChanged: _onPlaybackChanged,
  );
  StreamSubscription<String>? _ratingSubscription;
  bool _isDisposed = false;

  ValueListenable<AsyncState<PhraseSetState>> get state => _state;

  /// Ratings of the phrases: `itemKey → stars`.
  ValueListenable<Map<String, int>> get stars => _stars;

  /// Machine translations of phrases without one from the author.
  ValueListenable<Map<String, String>> get machineTranslations =>
      _machineTranslations;

  ValueListenable<String> get translationLanguage => model.translationLanguage;

  ValueListenable<bool> get canEdit => _canEdit;

  ValueListenable<LessonDownload> get download => model.download;

  ValueListenable<bool> get isOnline => model.isOnline;

  /// Offline a set can't be downloaded, only its download removed.
  bool get canToggleDownload =>
      model.isOnline.value || model.download.value is! NotDownloaded;

  /// What to tell the user when the set failed to open.
  String errorText(Object error) => switch (error) {
    NetworkFailure() => 'No connection. Download the set to study it offline.',
    Failure(:final message) => message,
    _ => '$error',
  };

  /// Where in the deck the card is.
  String counter(PhraseSetState state) =>
      state.isEmpty ? '0 / 0' : '${state.position + 1} / ${state.order.length}';

  /// `3 / 8 selected` while the deck is a part of the set.
  String? deckLabel(PhraseSetState state) => state.isPartialDeck
      ? '${state.deck.length} / ${state.lesson.phrases.length} selected'
      : null;

  /// Recall shows the flip button until the card is turned over.
  bool needsFlip(PhraseSetState state) =>
      state.mode == PhraseStudyMode.recall &&
      !state.isFlipped &&
      _translationOf(state.current) != null;

  PhraseCardFace cardFace(PhraseSetState state) {
    final phrase = state.current;
    final translation = _translationOf(phrase);
    if (needsFlip(state)) {
      return (
        text: translation!,
        secondary: null,
        hint: 'Recall the phrase, then flip the card',
      );
    }
    final missing =
        state.mode == PhraseStudyMode.recall && translation == null;
    return (
      text: phrase.text,
      secondary: translation,
      hint: missing ? _missingTranslationHint(state) : null,
    );
  }

  /// Rating of the phrase on the card.
  int currentStars(PhraseSetState state) =>
      _stars.value[phraseItemKey(state.current.id)] ?? 0;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _editSources.addListener(_onEditSourcesChanged);
    model.translationLanguage.addListener(_onTranslationLanguageChanged);
    _ratingSubscription = model.ratingChanges.listen(
      (_) => unawaited(_loadStars()),
    );
    unawaited(_open());
    unawaited(_loadStars());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _editSources.removeListener(_onEditSourcesChanged);
    model.translationLanguage.removeListener(_onTranslationLanguageChanged);
    unawaited(_ratingSubscription?.cancel());
    unawaited(_playback.dispose());
    pageFocus.dispose();
    _state.dispose();
    _stars.dispose();
    _machineTranslations.dispose();
    _canEdit.dispose();
    super.dispose();
  }

  void back() => context.pop();

  Future<void> retry() {
    _state.value = const AsyncPending();
    return _open();
  }

  /// Opens the editor; the set reloads after it closes.
  Future<void> edit() async {
    await context.push(PhraseSetPage.editRouteTo(model.lessonId));
    if (!_isDisposed) await _open();
  }

  Future<void> toggleDownload() async {
    try {
      await model.toggleDownload();
    } on Failure catch (failure) {
      _showMessage(failure.message);
    }
  }

  void togglePlay() => unawaited(_playback.togglePlay());

  void next() => unawaited(_playback.step(1));

  void previous() => unawaited(_playback.step(-1));

  void flip() => unawaited(_playback.flip());

  void setMode(PhraseStudyMode mode) => unawaited(_playback.setMode(mode));

  void toggleShuffle() => _playback.toggleShuffle();

  void toggleRepeat() => _playback.toggleRepeating();

  void toggleLoop() => _playback.toggleLooping();

  void resetDeck() => unawaited(_playback.resetDeck());

  Future<void> pickSpeed() async {
    final current = _state.value.value;
    if (current == null) return;
    final selected = await showAppBottomSheet<double>(
      context: context,
      title: 'Speed',
      builder: (_) => PlaybackSpeedSheet(current: current.speed),
    );
    if (selected != null) await _playback.setSpeed(selected);
  }

  /// Rates the phrase on the card.
  Future<void> rate(int stars) async {
    final current = _state.value.value;
    if (current == null || current.isEmpty) return;
    try {
      await model.rate(
        phraseItemKey(current.current.id),
        stars,
        current.lesson,
      );
    } on Failure catch (failure) {
      _showMessage(failure.message);
    }
  }

  /// The phrase list; with [selecting] it builds the deck to study.
  Future<void> openPhrases({required bool selecting}) async {
    if (selecting) _playback.startSelecting();
    await showAppBottomSheet<void>(
      context: context,
      title: selecting ? 'Choose phrases' : 'Phrases',
      builder: (sheetContext) => ListenableBuilder(
        listenable: Listenable.merge([_state, _stars]),
        builder: (_, _) => switch (_state.value.value) {
          final current? => PhraseSelectPanel(
            texts: [for (final phrase in current.lesson.phrases) phrase.text],
            stars: _phraseStars(current),
            currentIndex: current.phraseIndex,
            isSelecting: current.isSelecting,
            selection: current.selection,
            onTap: (index) {
              if (current.isSelecting) {
                _playback.toggleSelected(index);
              } else {
                unawaited(_playback.goTo(index));
                Navigator.of(sheetContext).pop();
              }
            },
            onPickAll: () => _playback.select(
              List.generate(current.lesson.phrases.length, (i) => i),
            ),
            onPickUnrated: () => _pickRated(current, 0, 0),
            onPickWeak: () => _pickRated(current, 1, 3),
            onClear: () => _playback.select(const []),
            onApply: () {
              unawaited(_playback.applySelection());
              Navigator.of(sheetContext).pop();
            },
          ),
          null => const SizedBox.shrink(),
        },
      ),
    );
    if (!_isDisposed && (_state.value.value?.isSelecting ?? false)) {
      _playback.stopSelecting();
    }
  }

  /// A horizontal swipe on the card: left goes on, right goes back.
  void swipe(double velocity) {
    if (velocity.abs() < 300) return;
    if (velocity < 0) {
      next();
    } else {
      previous();
    }
  }

  /// Arrows walk the deck, space flips or plays, digits rate.
  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final current = _state.value.value;
    if (current == null || current.isEmpty) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        next();
      case LogicalKeyboardKey.arrowLeft:
        previous();
      case LogicalKeyboardKey.space:
        needsFlip(current) ? flip() : togglePlay();
      case LogicalKeyboardKey.digit1 ||
          LogicalKeyboardKey.digit2 ||
          LogicalKeyboardKey.digit3 ||
          LogicalKeyboardKey.digit4 ||
          LogicalKeyboardKey.digit5:
        if (needsFlip(current)) return KeyEventResult.ignored;
        final stars = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
        unawaited(rate(stars == currentStars(current) ? 0 : stars));
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _pickRated(PhraseSetState state, int minStars, int maxStars) =>
      _playback.select(
        phrasesRatedBetween(
          state.lesson.itemKeys,
          _stars.value,
          minStars: minStars,
          maxStars: maxStars,
        ),
      );

  List<int> _phraseStars(PhraseSetState state) => [
    for (final key in state.lesson.itemKeys) _stars.value[key] ?? 0,
  ];

  String? _translationOf(Phrase phrase) =>
      phrase.translationFor(model.translationLanguage.value) ??
      _machineTranslations.value[phrase.id];

  String _missingTranslationHint(PhraseSetState state) =>
      model.isTranslationPointless(state.lesson)
      ? 'The translation language matches the lesson language. '
            'Pick another one in Settings.'
      : 'No translation yet. It needs the network the first time.';

  Future<void> _open() async {
    try {
      final lesson = await model.loadLesson();
      if (_isDisposed) return;
      await _playback.open(lesson);
      unawaited(_loadMachineTranslations());
    } catch (error, stackTrace) {
      if (!_isDisposed) _state.value = AsyncFailed(error, stackTrace);
    }
  }

  Future<void> _loadMachineTranslations() async {
    final lesson = _state.value.value?.lesson;
    if (lesson == null) return;
    try {
      final translations = await model.translateMissing(
        lesson,
        model.translationLanguage.value,
      );
      if (!_isDisposed) _machineTranslations.value = translations;
    } on Failure catch (_) {
      // Offline the card falls back to the phrase itself.
    }
  }

  Future<void> _loadStars() async {
    try {
      final stars = await model.loadStars();
      if (!_isDisposed) _stars.value = stars;
    } on Failure catch (_) {
      // The stars stay as they were; the next change reloads them.
    }
  }

  void _onPlaybackChanged(PhraseSetState state) {
    if (!_isDisposed) _state.value = AsyncReady(state);
  }

  void _onTranslationLanguageChanged() {
    _machineTranslations.value = const {};
    unawaited(_loadMachineTranslations());
  }

  void _onEditSourcesChanged() => _canEdit.value = _currentCanEdit();

  bool _currentCanEdit() {
    final lesson = _state.value.value?.lesson;
    return lesson != null &&
        model.isOnline.value &&
        canModifyLesson(model.role.value, lesson);
  }

  void _showMessage(String message) {
    if (!isMounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
