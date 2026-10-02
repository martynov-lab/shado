import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../lessons/presentation/screens/lesson/lesson_page.dart';
import '../../../lessons/presentation/screens/lessons/lessons_page.dart';
import 'home_lesson_tile.dart';
import 'home_model.dart';
import 'home_overview.dart';
import 'home_page.dart';

HomeWidgetModel homeWidgetModelFactory(BuildContext context) => HomeWidgetModel(
  HomeModel(ProviderScope.containerOf(context, listen: false)),
);

class HomeWidgetModel extends WidgetModel<HomePage, HomeModel> {
  HomeWidgetModel(super.model);

  late final ValueNotifier<HomeOverview> _overview = ValueNotifier(
    _currentOverview(),
  );
  final ValueNotifier<double> _heroProgress = ValueNotifier(0);
  late final Listenable _sources = Listenable.merge([
    model.summary,
    model.history,
    model.email,
    model.lessons,
  ]);
  HomeLessonTile? _hero;

  ValueListenable<HomeOverview> get overview => _overview;

  /// Progress of the first lesson, shown in the continue card.
  ValueListenable<double> get heroProgress => _heroProgress;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _sources.addListener(_onSourcesChanged);
    _updateHeroProgress();
  }

  @override
  void dispose() {
    _sources.removeListener(_onSourcesChanged);
    _overview.dispose();
    _heroProgress.dispose();
    super.dispose();
  }

  void openLessons() => context.go(LessonsPage.routePath);

  void openLesson(String lessonId) =>
      context.push(LessonPage.routeTo(lessonId));

  void _onSourcesChanged() {
    _overview.value = _currentOverview();
    _updateHeroProgress();
  }

  HomeOverview _currentOverview() => HomeOverview.from(
    summary: model.summary.value,
    history: model.history.value,
    email: model.email.value,
    catalog: model.lessons.value,
  );

  void _updateHeroProgress() {
    final lessons = _overview.value.lessons;
    final hero = lessons.isEmpty ? null : lessons.first;
    if (hero?.id == _hero?.id) return;
    _hero = hero;
    _heroProgress.value = 0;
    if (hero != null) unawaited(_loadHeroProgress(hero));
  }

  Future<void> _loadHeroProgress(HomeLessonTile hero) async {
    try {
      final progress = await model.lessonProgress(hero.id, hero.segmentCount);
      if (isMounted && _hero?.id == hero.id) _heroProgress.value = progress;
    } catch (_) {
      return;
    }
  }
}
