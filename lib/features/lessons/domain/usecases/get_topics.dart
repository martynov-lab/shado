import '../entities/lesson_category.dart';
import '../repositories/lesson_repository.dart';

/// Справочник тем для выпадающего списка на экране создания урока.
///
/// Темы правит владелец, поэтому список берётся с сервера при каждом входе на
/// экран: тему могли переименовать или удалить с другого устройства.
class GetTopics {
  const GetTopics(this._repository);

  final LessonRepository _repository;

  Future<List<Topic>> call() async {
    final topics = await _repository.getTopics();
    // Тема по умолчанию («Other») в списке не нужна: её роль играет пункт
    // «без темы», и сервер подставит её сам.
    final selectable = topics.where((topic) => !topic.isDefault).toList();
    selectable.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return selectable;
  }
}
