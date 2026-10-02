import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../languages/domain/entities/language.dart';
import '../../../domain/entities/folder.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_category.dart';
import '../../../domain/entities/lessons_filter.dart';
import '../../../domain/lesson_permissions.dart';
import '../../widgets/delete_lesson_dialog.dart';
import '../../widgets/folder_editor_dialog.dart';
import '../../widgets/lessons_filter_group_options.dart';
import '../folder/folder_page.dart';
import '../lesson/lesson_page.dart';
import 'lesson_filter_group.dart';
import 'lesson_list_item.dart';
import 'lessons_content.dart';
import 'lessons_model.dart';
import 'lessons_page.dart';

LessonsWidgetModel lessonsWidgetModelFactory(BuildContext context) =>
    LessonsWidgetModel(
      LessonsModel(ProviderScope.containerOf(context, listen: false)),
    );

class LessonsWidgetModel extends WidgetModel<LessonsPage, LessonsModel> {
  LessonsWidgetModel(super.model);

  final ValueNotifier<LessonsFilter> _filter = ValueNotifier(
    const LessonsFilter(),
  );
  final ValueNotifier<AsyncState<List<Topic>>> _topics = ValueNotifier(
    const AsyncPending(),
  );
  final ValueNotifier<Map<String, double>> _progress = ValueNotifier(const {});
  late final ValueNotifier<AsyncState<LessonsContent>> _content = ValueNotifier(
    _currentContent(),
  );
  late final ValueNotifier<List<LessonFilterGroup>> _groups = ValueNotifier(
    _currentGroups(),
  );
  late final ValueNotifier<bool> _canAuthor = ValueNotifier(
    _currentCanAuthor(),
  );
  late final Listenable _contentSources = Listenable.merge([
    model.library,
    model.lessons,
    model.role,
    _filter,
    _progress,
  ]);
  StreamSubscription<void>? _resetSubscription;

  ValueListenable<AsyncState<LessonsContent>> get content => _content;
  ValueListenable<LessonsFilter> get filter => _filter;
  ValueListenable<AsyncState<List<Topic>>> get topics => _topics;
  ValueListenable<List<Accent>> get accents => model.accents;

  /// The accent group appears only for languages with accents.
  ValueListenable<List<LessonFilterGroup>> get groups => _groups;

  /// Only authors may create folders.
  ValueListenable<bool> get canAuthor => _canAuthor;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _contentSources.addListener(_onContentSourcesChanged);
    model.accents.addListener(_onAccentsChanged);
    model.role.addListener(_onRoleChanged);
    model.lessons.addListener(_onLessonsChanged);
    _resetSubscription = model.catalogResets.listen(
      (_) => _filter.value = const LessonsFilter(),
    );
    unawaited(_loadTopics());
    unawaited(_loadProgress(model.lessons.value));
  }

  @override
  void dispose() {
    _contentSources.removeListener(_onContentSourcesChanged);
    model.accents.removeListener(_onAccentsChanged);
    model.role.removeListener(_onRoleChanged);
    model.lessons.removeListener(_onLessonsChanged);
    _resetSubscription?.cancel();
    _filter.dispose();
    _topics.dispose();
    _progress.dispose();
    _content.dispose();
    _groups.dispose();
    _canAuthor.dispose();
    super.dispose();
  }

  Future<void> refresh() => model.refresh();

  Future<void> retry() => model.retryLibrary();

  void setQuery(String query) => _filter.value = _filter.value.withQuery(query);

  void setFilter(LessonsFilter filter) => _filter.value = filter;

  void clearFilters() => _filter.value = _filter.value.cleared();

  Future<void> openFilterGroup(LessonFilterGroup group) =>
      showAppBottomSheet<void>(
        context: context,
        title: group.title,
        builder: (_) => ListenableBuilder(
          listenable: Listenable.merge([_filter, _topics, model.accents]),
          builder: (_, _) => SingleChildScrollView(
            child: LessonsFilterGroupOptions(
              group: group,
              filter: _filter.value,
              topics: _topics.value,
              accents: model.accents.value,
              onChanged: setFilter,
            ),
          ),
        ),
      );

  void openLesson(Lesson lesson) => context.push(LessonPage.routeTo(lesson.id));

  void openFolder(Folder folder) => context.push(FolderPage.routeTo(folder.id));

  Future<void> deleteLesson(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteLessonDialog(lessonTitle: lesson.title),
    );
    if (confirmed != true) return;
    await model.deleteLesson(lesson.id);
  }

  /// Creates a folder and opens it.
  Future<void> createFolder() async {
    final context = this.context;
    final title = await showDialog<String>(
      context: context,
      builder: (_) =>
          const FolderEditorDialog(title: 'New folder', confirmLabel: 'Create'),
    );
    if (title == null) return;
    try {
      final folder = await model.createFolder(title);
      if (context.mounted) openFolder(folder);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create the folder: $error')),
      );
    }
  }

  void _onContentSourcesChanged() => _content.value = _currentContent();

  void _onAccentsChanged() => _groups.value = _currentGroups();

  void _onRoleChanged() => _canAuthor.value = _currentCanAuthor();

  void _onLessonsChanged() => unawaited(_loadProgress(model.lessons.value));

  AsyncState<LessonsContent> _currentContent() {
    final filter = _filter.value;
    final role = model.role.value;
    final progress = _progress.value;
    return model.library.value.mapValue(
      (library) => LessonsContent(
        items: [
          for (final lesson in filter.visibleLessons(
            catalog: model.lessons.value,
            rootLessons: library.lessons,
          ))
            LessonListItem(
              lesson: lesson,
              progress: progress[lesson.id] ?? 0,
              canModify: canModifyLesson(role, lesson),
            ),
        ],
        folders: filter.visibleFolders(library.folders),
        isLibraryEmpty: library.isEmpty,
      ),
    );
  }

  List<LessonFilterGroup> _currentGroups() {
    final hasAccents = model.accents.value.isNotEmpty;
    return [
      for (final group in LessonFilterGroup.values)
        if (hasAccents || group != LessonFilterGroup.accent) group,
    ];
  }

  bool _currentCanAuthor() => canCreateLessons(model.role.value);

  Future<void> _loadTopics() async {
    final topics = await AsyncState.guard(model.loadTopics);
    if (isMounted) _topics.value = topics;
  }

  Future<void> _loadProgress(List<Lesson> lessons) async {
    try {
      final values = await Future.wait(lessons.map(model.lessonProgress));
      if (!isMounted) return;
      _progress.value = {
        for (var i = 0; i < lessons.length; i++) lessons[i].id: values[i],
      };
    } catch (_) {
      return;
    }
  }
}
