import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/async/async_state.dart';

import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/screens/lesson/lesson_page.dart';
import 'progress_model.dart';
import 'progress_overview.dart';
import 'progress_page.dart';

ProgressWidgetModel progressWidgetModelFactory(BuildContext context) =>
    ProgressWidgetModel(
      ProgressModel(ProviderScope.containerOf(context, listen: false)),
    );

class ProgressWidgetModel extends WidgetModel<ProgressPage, ProgressModel> {
  ProgressWidgetModel(super.model);

  late final ValueNotifier<AsyncState<ProgressOverview>> _overview =
      ValueNotifier(_currentOverview());
  late final Listenable _sources = Listenable.merge([
    model.summary,
    model.history,
    model.lessons,
  ]);

  ValueListenable<AsyncState<ProgressOverview>> get overview => _overview;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _sources.addListener(_onSourcesChanged);
  }

  @override
  void dispose() {
    _sources.removeListener(_onSourcesChanged);
    _overview.dispose();
    super.dispose();
  }

  Future<void> retry() => model.refreshSummary();

  void openLesson(Lesson lesson) => context.push(LessonPage.routeTo(lesson.id));

  void _onSourcesChanged() => _overview.value = _currentOverview();

  AsyncState<ProgressOverview> _currentOverview() =>
      model.summary.value.mapValue(
        (summary) => ProgressOverview.from(
          summary,
          model.history.value,
          model.lessons.value,
        ),
      );
}
