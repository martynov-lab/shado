import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/settings_providers.dart';

import '../../../lessons/domain/entities/lesson_category.dart';
import '../../../lessons/domain/repositories/topic_repository.dart';
import '../../../settings/domain/services/completion_threshold_service.dart';

/// Data and actions of the management screen: the completion threshold and
/// the topic directory.
class ManagementModel extends ElementaryModel {
  ManagementModel(this._container)
    : _threshold = _container.read(completionThresholdServiceProvider),
      _topics = _container.read(topicRepositoryProvider);

  final ProviderContainer _container;
  final CompletionThresholdService _threshold;
  final TopicRepository _topics;

  late final ValueNotifier<int?> _completionReps = ValueNotifier(
    _threshold.reps,
  );
  StreamSubscription<int>? _thresholdSubscription;

  /// `null` until the threshold is loaded.
  ValueListenable<int?> get completionReps => _completionReps;

  @override
  void init() {
    super.init();
    _thresholdSubscription = _threshold.changes.listen(
      (reps) => _completionReps.value = reps,
    );
    _threshold.load().ignore();
  }

  /// Throws a `ValidationFailure` for a value out of range.
  Future<void> saveCompletionReps(int reps) => _threshold.save(reps);

  Future<List<Topic>> loadTopics() => _topics.list();

  Future<void> createTopic(String name) => _topics.create(name);

  Future<void> renameTopic({required String id, required String name}) =>
      _topics.rename(id: id, name: name);

  /// Lessons of the deleted topic move to the default one, so the lesson
  /// catalog is reloaded as well.
  Future<void> deleteTopic(String id) async {
    await _topics.delete(id);
    _container.read(lessonCatalogServiceProvider).refreshLessons().ignore();
  }

  @override
  void dispose() {
    _thresholdSubscription?.cancel();
    _completionReps.dispose();
    super.dispose();
  }
}
