import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/elementary/stream_value_notifier.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/settings_providers.dart';

import '../../../lessons/domain/entities/lesson_category.dart';
import '../../../lessons/domain/repositories/topic_repository.dart';
import '../../../settings/domain/entities/tts_provider_settings.dart';
import '../../../settings/domain/services/tts_provider_service.dart';

/// Data and actions of the management screen: the voice-over provider and
/// the topic directory.
class ManagementModel extends ElementaryModel {
  ManagementModel(this._container)
    : _ttsProvider = _container.read(ttsProviderServiceProvider),
      _topics = _container.read(topicRepositoryProvider);

  final ProviderContainer _container;
  final TtsProviderService _ttsProvider;
  final TopicRepository _topics;

  late final StreamValueNotifier<TtsProviderSettings?> _ttsProviderSettings =
      StreamValueNotifier(_ttsProvider.settings, _ttsProvider.changes);

  /// `null` until the settings are loaded.
  ValueListenable<TtsProviderSettings?> get ttsProvider =>
      _ttsProviderSettings;

  @override
  void init() {
    super.init();
    _ttsProvider.load().ignore();
  }

  /// Switches the voice-over provider for every user.
  Future<void> selectTtsProvider(String name) => _ttsProvider.change(name);

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
    _ttsProviderSettings.dispose();
    super.dispose();
  }
}
