import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/auth_providers.dart';
import 'package:shado/di/lesson_providers.dart';

import '../../../../auth/domain/services/auth_service.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/lesson_visibility.dart';
import '../../../domain/services/lesson_catalog_service.dart';
import '../../../domain/usecases/get_lesson.dart';
import '../../../domain/usecases/update_lesson_content.dart';
import 'edit_lesson_state.dart';
import 'lesson_editor.dart';

/// Loading and saving the lesson being edited.
class EditLessonModel extends ElementaryModel {
  EditLessonModel(ProviderContainer container, this.lessonId)
    : _auth = container.read(authServiceProvider),
      _catalog = container.read(lessonCatalogServiceProvider),
      _getLesson = container.read(getLessonProvider),
      _updateLesson = container.read(updateLessonContentProvider);

  final String lessonId;
  final AuthService _auth;
  final LessonCatalogService _catalog;
  final GetLesson _getLesson;
  final UpdateLessonContent _updateLesson;

  late final StreamValueNotifier<bool> _isOwner = StreamValueNotifier(
    _auth.session.isOwner,
    _auth.changes.map((session) => session.isOwner),
  );

  /// The privacy switch is shown to the owner only.
  ValueListenable<bool> get isOwner => _isOwner;

  /// Reads the lesson and opens an editor for it; the caller disposes it.
  Future<LessonEditor> openEditor() async {
    final Lesson lesson = await _getLesson(lessonId);
    return LessonEditor(lesson, AudioPlayer());
  }

  /// Saves the edits and reloads the catalog. A version conflict is thrown.
  Future<void> save(EditLessonState state) async {
    await _updateLesson(
      lesson: state.lesson,
      title: state.title,
      rawText: state.text,
      boundaries: state.boundaries,
      trim: state.trim,
      isPublic: publicFlagForRole(
        _auth.session.user?.role,
        requested: state.isPublic,
      ),
    );
    _catalog.reload();
  }

  @override
  void dispose() {
    _isOwner.dispose();
    super.dispose();
  }
}
