import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';

/// Права на действия с уроками по роли — матрица §6.
///
/// Это подсказка для UI: спрятать кнопку, которой всё равно ответят `403`.
/// Источник истины — сервер: `404` чистит кеш в репозитории, `403` просто не
/// даёт действие. Поэтому правила здесь намеренно простые.
///
/// Приватный урок сервер отдаёт только автору, поэтому «вижу приватный» ⇒ «он
/// мой»: его правит и удаляет любой автор ([UserRole.canAuthor]). Публичный —
/// только admin и owner.

/// Кто вправе создавать уроки.
bool canCreateLessons(UserRole? role) => role?.canAuthor ?? false;

/// Кто вправе править и удалять конкретный урок.
bool canModifyLesson(UserRole? role, Lesson lesson) {
  if (role == null) return false;
  if (lesson.isPrivate) return role.canAuthor;
  return role.isAdmin || role.isOwner;
}

/// Кто вправе править состав и метаданные папки — по тем же правилам, что и
/// уроки (§6.2): приватную ведёт любой автор, публичную — admin и owner.
bool canModifyFolder(UserRole? role, Folder folder) {
  if (role == null) return false;
  if (folder.isPrivate) return role.canAuthor;
  return role.isAdmin || role.isOwner;
}
