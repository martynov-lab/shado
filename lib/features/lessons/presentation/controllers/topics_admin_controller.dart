import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/topic_remote_datasource.dart';
import '../../domain/entities/lesson_category.dart';
import 'lesson_providers.dart';
import 'lessons_controller.dart';

/// Управление справочником тем владельцем: создание, переименование, удаление
/// (§8.2). Список для чтения (фильтры, экран создания) живёт в [topicsProvider];
/// здесь — редактируемая копия для экрана «Управление».
///
/// После любой правки сбрасываем [topicsProvider], чтобы каталог и экран
/// создания перечитали темы. Права проверяет сервер, а не контроллер.
class TopicsAdminController extends AsyncNotifier<List<Topic>> {
  TopicRemoteDataSource get _topics => ref.read(topicRemoteDataSourceProvider);

  @override
  Future<List<Topic>> build() => _topics.list();

  /// Ошибки (пустое имя, повтор — `422`) уходят наверх: их показывает секция.
  Future<void> create(String name) => _mutate(() => _topics.create(name));

  Future<void> rename({required String id, required String name}) =>
      _mutate(() => _topics.rename(id: id, name: name));

  /// Удаляет тему. Её уроки переезжают на «Other», поэтому дополнительно
  /// перечитываем каталог — иначе в кеше останется старая разметка.
  Future<void> delete(String id) async {
    await _topics.delete(id);
    await _reload();
    unawaited(ref.read(lessonsControllerProvider.notifier).refresh());
  }

  Future<void> _mutate(Future<void> Function() action) async {
    await action();
    await _reload();
  }

  /// Перечитывает список (сортировку держит сервер) и сбрасывает кеш тем.
  Future<void> _reload() async {
    state = AsyncData(await _topics.list());
    ref.invalidate(topicsProvider);
  }
}

final topicsAdminControllerProvider =
    AsyncNotifierProvider.autoDispose<TopicsAdminController, List<Topic>>(
      TopicsAdminController.new,
    );
