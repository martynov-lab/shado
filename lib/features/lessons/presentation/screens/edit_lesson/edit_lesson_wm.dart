import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/async/async_state.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../domain/entities/audio_trim.dart';
import '../../widgets/segment_splitter/marked_text_controller.dart';
import '../../widgets/version_conflict_dialog.dart';
import 'edit_lesson_model.dart';
import 'edit_lesson_page.dart';
import 'edit_lesson_state.dart';
import 'lesson_editor.dart';

EditLessonWidgetModel editLessonWidgetModelFactory(BuildContext context) {
  final page = context.widget as EditLessonPage;
  return EditLessonWidgetModel(
    EditLessonModel(
      ProviderScope.containerOf(context, listen: false),
      page.lessonId,
    ),
  );
}

class EditLessonWidgetModel
    extends WidgetModel<EditLessonPage, EditLessonModel> {
  EditLessonWidgetModel(super.model);

  final TextEditingController titleController = TextEditingController();
  final MarkedTextController textController = MarkedTextController();

  /// While the screen itself holds the focus, space plays and pauses.
  final FocusNode pageFocus = FocusNode(debugLabel: 'edit-lesson-page');

  final ValueNotifier<AsyncState<EditLessonState>> _state = ValueNotifier(
    const AsyncPending(),
  );
  final ValueNotifier<int> _playheadMs = ValueNotifier(0);
  LessonEditor? _editor;
  bool _isDisposed = false;

  ValueListenable<AsyncState<EditLessonState>> get state => _state;

  /// Playhead in file milliseconds; follows the player while it plays.
  ValueListenable<int> get playheadMs => _playheadMs;

  ValueListenable<bool> get isOwner => model.isOwner;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    unawaited(_open());
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_closeEditor());
    titleController.dispose();
    textController.dispose();
    pageFocus.dispose();
    _state.dispose();
    _playheadMs.dispose();
    super.dispose();
  }

  void close() => Navigator.of(context).pop();

  void setTitle(String title) => _editor?.setTitle(title);
  void setText(String text) => _editor?.setText(text);
  void setPrivate(bool isPrivate) => _editor?.setPrivate(isPrivate);
  void setBoundaries(List<int> boundaries) =>
      _editor?.setBoundaries(boundaries);
  void insertMarker(String text, int ordinal) =>
      _editor?.insertMarker(text, ordinal);
  void removeMarker(int ordinal) => _editor?.removeMarker(ordinal);
  void setMarkerAtPlayhead(bool enabled) =>
      _editor?.setMarkerAtPlayhead(enabled);
  void startTrim() => _editor?.startTrim();
  void updateTrim(AudioTrim trim) => _editor?.updateTrim(trim);
  void applyTrim() => unawaited(_editor?.applyTrim());
  void cancelTrim() => unawaited(_editor?.cancelTrim());
  void togglePlay() => unawaited(_editor?.togglePlay());
  void seek(int positionMs) => unawaited(_editor?.seek(positionMs));

  /// Touching the waveform takes the focus off the text field.
  void focusPage() => pageFocus.requestFocus();

  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.space ||
        !node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    togglePlay();
    return KeyEventResult.handled;
  }

  /// Saves and closes the screen with `true`. On a version conflict offers
  /// to open the fresh version instead.
  Future<void> save() async {
    final editor = _editor;
    if (editor == null || !editor.state.value.canSave) return;
    final context = this.context;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    editor.setSaving(true);
    try {
      await model.save(editor.state.value);
      navigator.pop(true);
    } on ApiException catch (error) {
      if (!_isDisposed) editor.setSaving(false);
      if (!error.isVersionConflict) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to save: ${error.message}')),
        );
        return;
      }
      if (context.mounted) await _resolveConflict(context);
    } catch (error) {
      if (!_isDisposed) editor.setSaving(false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $error')));
    }
  }

  Future<void> _resolveConflict(BuildContext context) async {
    final reload = await showDialog<bool>(
      context: context,
      builder: (_) => const VersionConflictDialog(),
    );
    if (reload != true || _isDisposed) return;
    _state.value = const AsyncPending();
    await _open();
  }

  Future<void> _open() async {
    await _closeEditor();
    try {
      final editor = await model.openEditor();
      if (_isDisposed) {
        await editor.dispose();
        return;
      }
      _editor = editor;
      titleController.text = editor.state.value.title;
      textController.text = editor.state.value.text;
      editor.state.addListener(_onEditorChanged);
      editor.positionMs.addListener(_onEditorChanged);
      _onEditorChanged();
    } catch (error, stackTrace) {
      if (!_isDisposed) _state.value = AsyncFailed(error, stackTrace);
    }
  }

  Future<void> _closeEditor() async {
    final editor = _editor;
    _editor = null;
    if (editor == null) return;
    editor.state.removeListener(_onEditorChanged);
    editor.positionMs.removeListener(_onEditorChanged);
    await editor.dispose();
  }

  void _onEditorChanged() {
    final editor = _editor;
    if (editor == null || _isDisposed) return;
    final state = editor.state.value;
    // Text changed by the editor (a removed marker) goes back into the field.
    if (state.text != textController.text) textController.text = state.text;
    _state.value = AsyncReady(state);
    _playheadMs.value = editor.playheadMs;
  }
}
