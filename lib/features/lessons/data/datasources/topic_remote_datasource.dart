import '../../../../core/network/api_client.dart';
import '../../domain/entities/lesson_category.dart';

/// Справочник тем уроков.
///
/// В отличие от акцента и уровня темы правит владелец через админку, поэтому
/// список нужно спрашивать у сервера, а не зашивать в клиент (§6): тему могли
/// переименовать или удалить с другого устройства.
abstract interface class TopicRemoteDataSource {
  Future<List<Topic>> list();
}

class ApiTopicRemoteDataSource implements TopicRemoteDataSource {
  const ApiTopicRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<List<Topic>> list() async {
    final json = await _client.get('/v1/topics');
    return [
      for (final topic in (json['topics'] as List<dynamic>? ?? const []))
        Topic.fromJson(topic as Map<String, dynamic>),
    ];
  }
}
