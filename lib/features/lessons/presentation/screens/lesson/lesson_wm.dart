import 'dart:async';
import 'dart:math' as math;

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../settings/presentation/widgets/playback_speed_sheet.dart';
import '../../../domain/entities/lesson_download.dart';
import '../../../domain/lesson_permissions.dart';
import '../../../domain/usecases/add_phrase_from_story.dart';
import '../../widgets/lesson_segments_panel.dart';
import '../../widgets/phrase_set_picker_sheet.dart';
import '../edit_lesson/edit_lesson_page.dart';
import 'lesson_model.dart';
import 'lesson_page.dart';
import 'lesson_playback.dart';
import 'lesson_state.dart';

LessonWidgetModel lessonWidgetModelFactory(BuildContext context) {
  final page = context.widget as LessonPage;
  return LessonWidgetModel(
    LessonModel(
      ProviderScope.containerOf(context, listen: false),
      page.lessonId,
    ),
  );
}

class LessonWidgetModel extends WidgetModel<LessonPage, LessonModel> {
  LessonWidgetModel(super.model);

  /// While the screen holds the focus, arrows and space control playback.
  final FocusNode pageFocus = FocusNode(debugLabel: 'lesson-page');

  final ValueNotifier<AsyncState<LessonState>> _state = ValueNotifier(
    const AsyncPending(),
  );
  final ValueNotifier<double> _playedFraction = ValueNotifier(0);
  final ValueNotifier<AsyncState<String>?> _translation = ValueNotifier(null);
  final ValueNotifier<Map<String, int>> _stars = ValueNotifier(const {});
  StreamSubscription<String>? _ratingSubscription;
  late final ValueNotifier<bool> _canEdit = ValueNotifier(_currentCanEdit());
  late final Listenable _editSources = Listenable.merge([
    _state,
    model.role,
    model.isOnline,
  ]);
  late final LessonPlayback _playback = model.createPlayback(
    onChanged: _onPlaybackChanged,
    onPosition: _onPosition,
  );
  bool _isDisposed = false;

  /// Text the shown translation belongs to; empty while hidden.
  String _translatedText = '';

  ValueListenable<AsyncState<LessonState>> get state => _state;

  /// Played part of the shown range, `0..1`; `0` while stopped.
  ValueListenable<double> get playedFraction => _playedFraction;

  /// Translation of the shown text; `null` while hidden, a failure carries
  /// the message to show.
  ValueListenable<AsyncState<String>?> get translation => _translation;

  /// Ratings of the lesson items: `itemKey → stars`.
  ValueListenable<Map<String, int>> get stars => _stars;

  /// Rating of the shown range: the lowest of its segments.
  int playerStars(LessonState state) {
    final keys = state.playerItemKeys;
    if (keys.isEmpty) return 0;
    return keys.map((key) => _stars.value[key] ?? 0).reduce(math.min);
  }

  /// Rating of every segment, in lesson order.
  List<int> segmentStars(LessonState state) => [
    for (final key in state.lesson.itemKeys) _stars.value[key] ?? 0,
  ];

  /// The edit button follows the role and needs the network; the server
  /// still checks the rights.
  ValueListenable<bool> get canEdit => _canEdit;

  ValueListenable<LessonDownload> get download => model.download;

  ValueListenable<bool> get isOnline => model.isOnline;

  /// Offline a lesson can't be downloaded, only its download removed.
  bool get canToggleDownload =>
      model.isOnline.value || model.download.value is! NotDownloaded;

  /// What to tell the user when the lesson failed to open.
  String errorText(Object error) => switch (error) {
    NetworkFailure() =>
      'No connection. Download the lesson to study it offline.',
    Failure(:final message) => message,
    _ => '$error',
  };

  /// Opens the lesson again after it failed to load.
  Future<void> retry() {
    _state.value = const AsyncPending();
    return _open();
  }

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _editSources.addListener(_onEditSourcesChanged);
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
    unawaited(_ratingSubscription?.cancel());
    unawaited(_playback.dispose());
    pageFocus.dispose();
    _state.dispose();
    _playedFraction.dispose();
    _translation.dispose();
    _stars.dispose();
    _canEdit.dispose();
    super.dispose();
  }

  void back() => context.pop();

  /// Opens the editor and reads the lesson again after a save.
  Future<void> edit() async {
    final saved = await context.push<bool>(
      EditLessonPage.routeTo(model.lessonId),
    );
    if (saved != true || _isDisposed) return;
    await _playback.reset();
    _state.value = const AsyncPending();
    await _open();
    if (!_isDisposed) pageFocus.requestFocus();
  }

  /// Downloads the lesson for offline study or removes the download.
  Future<void> toggleDownload() async {
    final context = this.context;
    try {
      await model.toggleDownload();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download the lesson: $error')),
      );
    }
  }

  Future<void> pickSpeed() async {
    final current = _state.value.value;
    if (current == null) return;
    final selected = await showAppBottomSheet<double>(
      context: context,
      title: 'Playback speed',
      builder: (_) => PlaybackSpeedSheet(current: current.speed),
    );
    if (selected == null) return;
    await _playback.setSpeed(selected);
  }

  /// The segment list as a sheet on phones; picking a segment closes it.
  Future<void> openSegments() => showAppBottomSheet<void>(
    context: context,
    title: 'Segments',
    builder: (sheetContext) => ListenableBuilder(
      listenable: Listenable.merge([_state, _stars]),
      builder: (_, _) => switch (_state.value.value) {
        final current? => LessonSegmentsPanel(
          state: current,
          segmentStars: segmentStars(current),
          shrinkWrap: true,
          onSegmentPressed: (index) {
            goToSegment(index);
            Navigator.of(sheetContext).pop();
          },
          onSelectPressed: toggleSelection,
          onStartSelecting: startSelecting,
          onSelectAll: selectAll,
          onClearSelection: clearSelection,
          onDone: () {
            if (_playback.finishSelecting()) Navigator.of(sheetContext).pop();
          },
          onToggleLoop: toggleLoop,
          onAddToPhrases: canAddToPhrases(current)
              ? () => unawaited(addSelectionToPhraseSet())
              : null,
        ),
        null => const SizedBox.shrink(),
      },
    ),
  );

  void togglePlayCurrent() => unawaited(_playback.togglePlayCurrent());

  void next() => unawaited(_playback.next());

  void previous() => unawaited(_playback.previous());

  void toggleLoop() => _playback.toggleLoop();

  void goToSegment(int index) => unawaited(_playback.goToSegment(index));

  void toggleSelection(int index) => _playback.toggleSelection(index);

  void startSelecting() => _playback.startSelecting();

  void selectAll() => _playback.selectAll();

  void clearSelection() => _playback.clearSelection();

  /// Whether the selection can become a phrase: 1–2 segments, online.
  bool canAddToPhrases(LessonState state) {
    final selection = state.selection;
    return selection != null &&
        selection.length <= kMaxSegmentsPerPhrase &&
        model.isOnline.value;
  }

  /// Adds the selected segments as a phrase to a set the user picks.
  Future<void> addSelectionToPhraseSet() async {
    final current = _state.value.value;
    final range = current?.selection;
    if (current == null || range == null) return;
    final context = this.context;
    try {
      final sets = await model.phraseSetsFor(current.lesson);
      if (!context.mounted) return;
      final choice = await showAppBottomSheet<String>(
        context: context,
        title: 'Add to a phrase set',
        builder: (_) => PhraseSetPickerSheet(
          sets: [for (final set in sets) (set.id, set.title)],
        ),
      );
      if (choice == null) return;
      final target = sets.where((set) => set.id == choice).firstOrNull;
      final saved = await model.addToPhraseSet(
        current.lesson,
        range,
        target: target,
      );
      _showMessage('Added to "${saved.title}"');
    } on Failure catch (failure) {
      _showMessage(failure.message);
    }
  }

  /// Rates the shown range; every segment of it gets [stars].
  Future<void> rate(int stars) async {
    final current = _state.value.value;
    if (current == null) return;
    try {
      await model.rate(current.playerItemKeys, stars, current.lesson);
    } on Failure catch (failure) {
      _showMessage(failure.message);
    }
  }

  /// Shows the translation of the shown text, or hides it.
  void toggleTranslation() {
    _translatedText = '';
    if (_translation.value != null) {
      _translation.value = null;
      return;
    }
    _translation.value = const AsyncPending();
    unawaited(_translateShown());
  }

  /// Leaves selection mode keeping the picked range.
  void finishSelecting() => _playback.finishSelecting();

  /// Arrows walk the segments, Shift grows the selection, space plays,
  /// Escape clears the selection and then leaves selection mode.
  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final shift = HardwareKeyboard.instance.isShiftPressed;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _playback.moveFocus(1, extend: shift);
      case LogicalKeyboardKey.arrowUp:
        _playback.moveFocus(-1, extend: shift);
      case LogicalKeyboardKey.space:
        if (event is KeyRepeatEvent) return KeyEventResult.handled;
        unawaited(_playback.togglePlayFocused());
      case LogicalKeyboardKey.escape:
        final current = _state.value.value;
        if (current == null) return KeyEventResult.ignored;
        if (current.selection != null) {
          _playback.clearSelection();
        } else if (current.isSelecting) {
          _playback.stopSelecting();
        } else {
          return KeyEventResult.ignored;
        }
      case LogicalKeyboardKey.digit1 ||
          LogicalKeyboardKey.digit2 ||
          LogicalKeyboardKey.digit3 ||
          LogicalKeyboardKey.digit4 ||
          LogicalKeyboardKey.digit5:
        final current = _state.value.value;
        if (current == null) return KeyEventResult.ignored;
        final stars =
            event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
        unawaited(rate(stars == playerStars(current) ? 0 : stars));
      case LogicalKeyboardKey.keyA:
        if (!HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isMetaPressed) {
          return KeyEventResult.ignored;
        }
        _playback.selectAll();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _open() async {
    try {
      final lesson = await model.loadLesson();
      if (!_isDisposed) await _playback.open(lesson);
    } catch (error, stackTrace) {
      if (!_isDisposed) _state.value = AsyncFailed(error, stackTrace);
    }
  }

  void _onPlaybackChanged(LessonState state) {
    if (_isDisposed) return;
    _state.value = AsyncReady(state);
    if (!state.isPlayerPlaying) _playedFraction.value = 0;
    if (_translation.value != null) unawaited(_translateShown());
  }

  Future<void> _translateShown() async {
    final current = _state.value.value;
    if (current == null) return;
    final text = current.playerText;
    if (text == _translatedText) return;
    _translatedText = text;
    final language = current.lesson.language;
    if (model.isTranslationPointless(language)) {
      _translation.value = const AsyncFailed(
        'The translation language matches the lesson language. '
        'Pick another one in Settings.',
      );
      return;
    }
    final cached = model.cachedTranslation(text, language);
    if (cached != null) {
      _translation.value = AsyncReady(cached);
      return;
    }
    _translation.value = const AsyncPending();
    try {
      final result = await model.translate(text, language);
      if (_isCurrentTranslation(text)) _translation.value = AsyncReady(result);
    } catch (error, stackTrace) {
      if (_isCurrentTranslation(text)) {
        _translation.value = AsyncFailed(
          _translationErrorText(error),
          stackTrace,
        );
      }
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

  void _showMessage(String message) {
    if (!isMounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isCurrentTranslation(String text) =>
      !_isDisposed && _translation.value != null && _translatedText == text;

  String _translationErrorText(Object error) => switch (error) {
    NetworkFailure() => 'No connection. The translation needs the network.',
    Failure(:final message) => message,
    _ => '$error',
  };

  void _onPosition(int positionMs) {
    final current = _state.value.value;
    if (_isDisposed || current == null || !current.isPlayerPlaying) return;
    final duration = current.playerEndMs - current.playerStartMs;
    if (duration <= 0) return;
    _playedFraction.value = ((positionMs - current.playerStartMs) / duration)
        .clamp(0.0, 1.0);
  }

  void _onEditSourcesChanged() => _canEdit.value = _currentCanEdit();

  bool _currentCanEdit() {
    final lesson = _state.value.value?.lesson;
    return lesson != null &&
        model.isOnline.value &&
        canModifyLesson(model.role.value, lesson);
  }
}
