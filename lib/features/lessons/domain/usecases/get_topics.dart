import '../entities/lesson_category.dart';
import '../repositories/lesson_repository.dart';

/// Topic directory for the dropdown on the lesson creation screen.
class GetTopics {
  const GetTopics(this._repository);

  final LessonRepository _repository;

  Future<List<Topic>> call() async {
    final topics = await _repository.getTopics();
    // The default topic is represented by the no-topic item.
    final selectable = topics.where((topic) => !topic.isDefault).toList();
    selectable.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return selectable;
  }
}
