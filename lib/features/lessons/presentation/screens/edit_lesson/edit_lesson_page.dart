import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';

import '../../widgets/edit_lesson_form.dart';
import '../../widgets/lesson_editor_header.dart';
import '../lesson/lesson_page.dart';
import 'edit_lesson_wm.dart';

/// Lesson editing: text split and segment boundaries; returns `true` when
/// saved.
class EditLessonPage extends ElementaryWidget<EditLessonWidgetModel> {
  const EditLessonPage({super.key, required this.lessonId})
    : super(editLessonWidgetModelFactory);

  /// Tail of the nested edit route.
  static const String routeSegment = 'edit';

  static String routeTo(String lessonId) =>
      '${LessonPage.routeTo(lessonId)}/$routeSegment';

  final String lessonId;

  @override
  Widget build(EditLessonWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([wm.state, wm.playheadMs, wm.isOwner]),
      builder: (context, _) {
        final state = wm.state.value.value;

        return Scaffold(
          backgroundColor: context.colors.bg,
          body: SafeArea(
            child: Column(
              children: [
                LessonEditorHeader(
                  title: 'Edit lesson',
                  onBack: wm.close,
                  onCancel: wm.close,
                  primaryLabel: 'Save',
                  onPrimary: (state?.canSave ?? false)
                      ? () => unawaited(wm.save())
                      : null,
                  primaryLoading: state?.isSaving ?? false,
                ),
                Expanded(
                  child: switch (wm.state.value) {
                    AsyncFailed(:final error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s8),
                        child: Text('$error', textAlign: TextAlign.center),
                      ),
                    ),
                    AsyncReady(:final value) => Focus(
                      focusNode: wm.pageFocus,
                      autofocus: true,
                      onKeyEvent: wm.handleKey,
                      child: EditLessonForm(
                        state: value,
                        playheadMs: wm.playheadMs.value,
                        isOwner: wm.isOwner.value,
                        titleController: wm.titleController,
                        textController: wm.textController,
                        onTitleChanged: wm.setTitle,
                        onPrivateChanged: wm.setPrivate,
                        onTextChanged: wm.setText,
                        onMarkerInserted: wm.insertMarker,
                        onMarkerRemoved: wm.removeMarker,
                        onWaveformTouched: wm.focusPage,
                        onPlayPressed: wm.togglePlay,
                        onSeek: wm.seek,
                        onBoundariesChanged: wm.setBoundaries,
                        onMarkerAtPlayheadChanged: wm.setMarkerAtPlayhead,
                        onTrimChanged: wm.updateTrim,
                        onTrimStart: wm.startTrim,
                        onTrimApply: wm.applyTrim,
                        onTrimCancel: wm.cancelTrim,
                      ),
                    ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
