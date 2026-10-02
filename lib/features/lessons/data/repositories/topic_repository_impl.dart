import '../../domain/entities/lesson_category.dart';
import '../../domain/repositories/topic_repository.dart';
import '../datasources/topic_remote_datasource.dart';

class TopicRepositoryImpl implements TopicRepository {
  const TopicRepositoryImpl(this._remote);

  final TopicRemoteDataSource _remote;

  @override
  Future<List<Topic>> list() => _remote.list();

  @override
  Future<Topic> create(String name) => _remote.create(name);

  @override
  Future<Topic> rename({required String id, required String name}) =>
      _remote.rename(id: id, name: name);

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
