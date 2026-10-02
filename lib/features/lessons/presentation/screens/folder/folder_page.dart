import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';

import '../../widgets/folder_content.dart';
import '../../widgets/folder_error_view.dart';
import 'folder_wm.dart';

/// A single folder screen: its lessons, contents and metadata.
class FolderPage extends ElementaryWidget<FolderWidgetModel> {
  const FolderPage({super.key, required this.folderId})
    : super(folderWidgetModelFactory);

  /// Route template; [routeTo] builds a path to a specific folder.
  static const String routePath = '/folders/:id';

  static String routeTo(String folderId) => '/folders/$folderId';

  final String folderId;

  @override
  Widget build(FolderWidgetModel wm) {
    return ListenableBuilder(
      listenable: Listenable.merge([wm.folder, wm.canModify]),
      builder: (context, _) => Scaffold(
        backgroundColor: context.colors.bg,
        body: SafeArea(
          child: switch (wm.folder.value) {
            AsyncFailed(:final error) => FolderErrorView(
              message: '$error',
              onBack: wm.back,
            ),
            AsyncReady(:final value) => FolderContent(
              folder: value,
              canModify: wm.canModify.value,
              onBack: wm.back,
              onOpenLesson: wm.openLesson,
              onRename: wm.rename,
              onDelete: wm.delete,
              onAddLessons: wm.addLessons,
              onRemoveLesson: wm.removeLesson,
              onRefresh: wm.refresh,
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}
