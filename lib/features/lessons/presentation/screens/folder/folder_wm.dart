import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/async/async_state.dart';

import '../../../../home/presentation/screens/home_page.dart';
import '../../../domain/entities/folder.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/lesson_permissions.dart';
import '../../widgets/add_lessons_to_folder_sheet.dart';
import '../../widgets/delete_folder_dialog.dart';
import '../../widgets/folder_editor_dialog.dart';
import '../lesson/lesson_page.dart';
import 'folder_model.dart';
import 'folder_page.dart';

FolderWidgetModel folderWidgetModelFactory(BuildContext context) {
  final page = context.widget as FolderPage;
  return FolderWidgetModel(
    FolderModel(
      ProviderScope.containerOf(context, listen: false),
      page.folderId,
    ),
  );
}

class FolderWidgetModel extends WidgetModel<FolderPage, FolderModel> {
  FolderWidgetModel(super.model);

  final ValueNotifier<AsyncState<Folder>> _folder = ValueNotifier(
    const AsyncPending(),
  );
  late final ValueNotifier<bool> _canModify = ValueNotifier(
    _currentCanModify(),
  );
  late final Listenable _permissionSources = Listenable.merge([
    _folder,
    model.role,
  ]);

  ValueListenable<AsyncState<Folder>> get folder => _folder;

  /// Whether the user may rename the folder and change its lessons.
  ValueListenable<bool> get canModify => _canModify;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _permissionSources.addListener(_onPermissionSourcesChanged);
    unawaited(refresh());
  }

  @override
  void dispose() {
    _permissionSources.removeListener(_onPermissionSourcesChanged);
    _folder.dispose();
    _canModify.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    final folder = await AsyncState.guard(model.loadFolder);
    if (isMounted) _folder.value = folder;
  }

  /// Back to where the folder was opened from, or home after a deep link.
  void back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(HomePage.routePath);
    }
  }

  void openLesson(Lesson lesson) => context.push(LessonPage.routeTo(lesson.id));

  Future<void> rename() async {
    final current = _folder.value.value;
    if (current == null) return;
    final title = await showDialog<String>(
      context: context,
      builder: (_) => FolderEditorDialog(
        title: 'Rename folder',
        confirmLabel: 'Save',
        initialValue: current.title,
      ),
    );
    if (title == null) return;
    await _change(() => model.rename(current, title), 'Failed to save');
  }

  Future<void> delete() async {
    final current = _folder.value.value;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteFolderDialog(folderTitle: current.title),
    );
    if (confirmed != true) return;
    try {
      await model.deleteFolder();
      if (isMounted) back();
    } catch (error) {
      _showMessage('Failed to delete: $error');
    }
  }

  /// Offers the unfiled lessons that are not in the folder yet.
  Future<void> addLessons() async {
    final current = _folder.value.value;
    if (current == null) return;
    final present = {for (final lesson in current.lessons) lesson.id};
    final candidates = [
      for (final lesson in model.unfiledLessons)
        if (!present.contains(lesson.id)) lesson,
    ];
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddLessonsToFolderSheet(candidates: candidates),
    );
    if (selected == null || selected.isEmpty) return;
    await _change(() => model.addLessons(selected), 'Failed to add');
  }

  Future<void> removeLesson(String lessonId) =>
      _change(() => model.removeLesson(lessonId), 'Failed to remove');

  Future<void> _change(
    Future<Folder> Function() change,
    String failureText,
  ) async {
    try {
      final folder = await change();
      if (isMounted) _folder.value = AsyncReady(folder);
    } catch (error) {
      _showMessage('$failureText: $error');
    }
  }

  void _onPermissionSourcesChanged() => _canModify.value = _currentCanModify();

  bool _currentCanModify() {
    final folder = _folder.value.value;
    return folder != null && canModifyFolder(model.role.value, folder);
  }

  void _showMessage(String message) {
    if (!isMounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
