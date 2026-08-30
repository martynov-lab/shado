import 'lesson.dart';

/// Папка — авторская подборка уже созданных уроков (§6.2).
///
/// В списке приходит без уроков, только с их числом ([lessonCount]); сами уроки
/// живут в [lessons] лишь когда папку открыли (`GET /v1/folders/{id}`). Видимость
/// и права — те же, что у уроков: приватную видит только автор.
class Folder {
  const Folder({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.lessonCount,
    this.isPublic = true,
    this.lessons = const [],
  });

  final String id;
  final String title;

  /// Публичность папки. Приватную видит только автор.
  final bool isPublic;

  bool get isPrivate => !isPublic;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Версия агрегата — уезжает в `If-Match` при правке названия и видимости.
  final int version;

  /// Число уроков, видимых зрителю. Приходит и в списке, и в деталях.
  final int lessonCount;

  /// Уроки папки в порядке добавления. Пусто в списке папок — их тянут при
  /// открытии папки.
  final List<Lesson> lessons;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Folder &&
          other.id == id &&
          other.title == title &&
          other.isPublic == isPublic &&
          other.version == version &&
          other.lessonCount == lessonCount;

  @override
  int get hashCode =>
      Object.hash(id, title, isPublic, version, lessonCount);

  @override
  String toString() => 'Folder($id, "$title", $lessonCount уроков)';
}
