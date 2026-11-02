import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../add_lesson/add_lesson_page.dart';
import '../phrase_set_editor/phrase_set_editor_page.dart';
import 'add_lesson_kind_model.dart';
import 'add_lesson_kind_page.dart';

AddLessonKindWidgetModel addLessonKindWidgetModelFactory(
  BuildContext context,
) => AddLessonKindWidgetModel(AddLessonKindModel());

class AddLessonKindWidgetModel
    extends WidgetModel<AddLessonKindPage, AddLessonKindModel> {
  AddLessonKindWidgetModel(super.model);

  void createStory() => context.go(AddLessonPage.routePath);

  void createPhraseSet() => context.go(PhraseSetEditorPage.createPath);
}
