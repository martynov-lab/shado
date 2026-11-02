import '../../auth/domain/entities/auth_user.dart';
import 'entities/folder.dart';
import 'entities/lesson.dart';

/// Role-based lesson permissions — a UI hint; the server enforces them.


/// Who may create lessons.
bool canCreateLessons(UserRole? role) => role?.canAuthor ?? false;

/// Who may edit and delete a given lesson. A private lesson is visible to its
/// author only; the server sends no author, so a public phrase set counts
/// as editable by admins and the owner.
bool canModifyLesson(UserRole? role, Lesson lesson) {
  if (role == null) return false;
  if (lesson.isPrivate) return lesson.isExpressions || role.canAuthor;
  return role.isAdmin || role.isOwner;
}

/// Who may edit folder contents and metadata.
bool canModifyFolder(UserRole? role, Folder folder) {
  if (role == null) return false;
  if (folder.isPrivate) return role.canAuthor;
  return role.isAdmin || role.isOwner;
}
