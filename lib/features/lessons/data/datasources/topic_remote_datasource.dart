import '../../../../core/network/api_client.dart';
import '../../domain/entities/lesson_category.dart';

/// Server-side lesson topic directory.
abstract interface class TopicRemoteDataSource {
  Future<List<Topic>> list();

  /// Creates a topic with a name of up to 60 characters.
  Future<Topic> create(String name);

  /// Renames a topic.
  Future<Topic> rename({required String id, required String name});

  /// Deletes a topic; the server moves its lessons to the default one.
  Future<void> delete(String id);
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

  @override
  Future<Topic> create(String name) async {
    final response = await _client.post('/v1/topics', data: {'name': name});
    return Topic.fromJson(response.data!);
  }

  @override
  Future<Topic> rename({required String id, required String name}) async {
    final response = await _client.patch('/v1/topics/$id', data: {'name': name});
    return Topic.fromJson(response.data!);
  }

  @override
  Future<void> delete(String id) => _client.delete('/v1/topics/$id');
}
