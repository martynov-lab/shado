import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/topic_remote_datasource.dart';
import '../../domain/entities/lesson_category.dart';
import 'lesson_providers.dart';
import 'lessons_controller.dart';

/// Topic directory management: create, rename and delete.
class TopicsAdminController extends AsyncNotifier<List<Topic>> {
  TopicRemoteDataSource get _topics => ref.read(topicRemoteDataSourceProvider);

  @override
  Future<List<Topic>> build() => _topics.list();

  /// Creates a topic; errors bubble up.
  Future<void> create(String name) => _mutate(() => _topics.create(name));

  Future<void> rename({required String id, required String name}) =>
      _mutate(() => _topics.rename(id: id, name: name));

  /// Deletes a topic and re-reads the catalog: its lessons move to the default.
  Future<void> delete(String id) async {
    await _topics.delete(id);
    await _reload();
    unawaited(ref.read(lessonsControllerProvider.notifier).refresh());
  }

  Future<void> _mutate(Future<void> Function() action) async {
    await action();
    await _reload();
  }

  /// Re-reads the topic list and invalidates its cache.
  Future<void> _reload() async {
    state = AsyncData(await _topics.list());
    ref.invalidate(topicsProvider);
  }
}

final topicsAdminControllerProvider =
    AsyncNotifierProvider.autoDispose<TopicsAdminController, List<Topic>>(
      TopicsAdminController.new,
    );
