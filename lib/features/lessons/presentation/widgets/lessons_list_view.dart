import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';
import 'folder_list_row.dart';
import 'folders_section_header.dart';
import 'lesson_list_row.dart';
import 'lesson_row_divider.dart';

/// Lesson list with pull-to-refresh; the folder section shares the scroll.
class LessonsListView extends StatelessWidget {
  const LessonsListView({
    super.key,
    required this.lessons,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
    this.folders = const [],
    this.onOpenFolder,
    this.onCreateFolder,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.s4),
  });

  final List<Lesson> lessons;
  final void Function(Lesson) onOpen;
  final void Function(Lesson) onDelete;
  final Future<void> Function() onRefresh;

  /// Folders shown above the lesson list.
  final List<Folder> folders;
  final void Function(Folder)? onOpenFolder;

  /// Creates a folder; `null` hides the button from non-authors.
  final VoidCallback? onCreateFolder;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Row descriptors are built up front; widgets stay lazy in `itemBuilder`.
    final entries = _buildEntries();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: padding,
        itemCount: entries.length,
        itemBuilder: (context, index) => _buildEntry(entries[index]),
      ),
    );
  }

  List<_Entry> _buildEntries() {
    final showFolders = folders.isNotEmpty || onCreateFolder != null;
    return [
      if (showFolders) ...[
        const _Entry.folderHeader(),
        for (final folder in folders) _Entry.folder(folder),
        if (lessons.isNotEmpty) const _Entry.divider(),
      ],
      for (var i = 0; i < lessons.length; i++) ...[
        if (i > 0) const _Entry.divider(),
        _Entry.lesson(lessons[i]),
      ],
    ];
  }

  Widget _buildEntry(_Entry entry) => switch (entry.kind) {
    _EntryKind.folderHeader => FoldersSectionHeader(onCreate: onCreateFolder),
    _EntryKind.folder => FolderListRow(
      folder: entry.folder!,
      onTap: () => onOpenFolder?.call(entry.folder!),
    ),
    _EntryKind.divider => const LessonRowDivider(),
    _EntryKind.lesson => LessonListRow(
      lesson: entry.lesson!,
      onTap: () => onOpen(entry.lesson!),
      onDelete: () => onDelete(entry.lesson!),
    ),
  };
}

enum _EntryKind { folderHeader, folder, divider, lesson }

/// List row descriptor — cheap so `itemBuilder` stays lazy.
class _Entry {
  const _Entry.folderHeader()
    : kind = _EntryKind.folderHeader,
      folder = null,
      lesson = null;
  const _Entry.folder(this.folder)
    : kind = _EntryKind.folder,
      lesson = null;
  const _Entry.divider()
    : kind = _EntryKind.divider,
      folder = null,
      lesson = null;
  const _Entry.lesson(this.lesson)
    : kind = _EntryKind.lesson,
      folder = null;

  final _EntryKind kind;
  final Folder? folder;
  final Lesson? lesson;
}
