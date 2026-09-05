import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/lesson.dart';

/// Role-based lesson permissions — a UI hint; the server enforces them.


/// Who may create lessons.
bool canCreateLessons(UserRole? role) => role?.canAuthor ?? false;

/// Who may edit and delete a given lesson.
bool canModifyLesson(UserRole? role, Lesson lesson) {
  if (role == null) return false;
  if (lesson.isPrivate) return role.canAuthor;
  return role.isAdmin || role.isOwner;
}

/// Who may edit folder contents and metadata.
bool canModifyFolder(UserRole? role, Folder folder) {
  if (role == null) return false;
  if (folder.isPrivate) return role.canAuthor;
  return role.isAdmin || role.isOwner;
}
