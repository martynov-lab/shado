import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../settings/presentation/widgets/playback_speed_sheet.dart';
import '../../../domain/lesson_permissions.dart';
import '../../widgets/lesson_segments_panel.dart';
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
  late final ValueNotifier<bool> _canEdit = ValueNotifier(_currentCanEdit());
  late final Listenable _editSources = Listenable.merge([_state, model.role]);
  late final LessonPlayback _playback = model.createPlayback(
    onChanged: _onPlaybackChanged,
    onPosition: _onPosition,
  );
  bool _isDisposed = false;

  ValueListenable<AsyncState<LessonState>> get state => _state;

  /// Played part of the shown range, `0..1`; `0` while stopped.
  ValueListenable<double> get playedFraction => _playedFraction;

  /// The edit button follows the role; the server still checks the rights.
  ValueListenable<bool> get canEdit => _canEdit;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _editSources.addListener(_onEditSourcesChanged);
    unawaited(_open());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _editSources.removeListener(_onEditSourcesChanged);
    unawaited(_playback.dispose());
    pageFocus.dispose();
    _state.dispose();
    _playedFraction.dispose();
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
    builder: (sheetContext) => ValueListenableBuilder(
      valueListenable: _state,
      builder: (_, state, _) => switch (state.value) {
        final current? => LessonSegmentsPanel(
          state: current,
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
  }

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
    return lesson != null && canModifyLesson(model.role.value, lesson);
  }
}
