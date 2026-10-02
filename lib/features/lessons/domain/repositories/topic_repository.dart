import '../entities/lesson_category.dart';

/// Lesson topics directory. Only the owner changes it.
abstract interface class TopicRepository {
  Future<List<Topic>> list();

  /// The name is up to 60 characters.
  Future<Topic> create(String name);

  Future<Topic> rename({required String id, required String name});

  /// The server moves lessons of the deleted topic to the default one.
  Future<void> delete(String id);
}
