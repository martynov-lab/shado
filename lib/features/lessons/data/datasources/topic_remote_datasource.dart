import '../../../../core/network/api_client.dart';
import '../../domain/entities/lesson_category.dart';

/// Справочник тем уроков (§8.2).
///
/// В отличие от акцента и уровня темы правит владелец через админку, поэтому
/// список нужно спрашивать у сервера, а не зашивать в клиент (§6): тему могли
/// переименовать или удалить с другого устройства. Читать список может любой,
/// править — только owner (роль проверяет сервер).
abstract interface class TopicRemoteDataSource {
  Future<List<Topic>> list();

  /// Создаёт тему. Имя до 60 символов, уникально без учёта регистра — иначе
  /// сервер отвечает `422` с готовым текстом.
  Future<Topic> create(String name);

  /// Переименовывает тему. Работает и для темы по умолчанию («Other»).
  Future<Topic> rename({required String id, required String name});

  /// Удаляет тему. Её уроки сервер переносит на «Other».
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
