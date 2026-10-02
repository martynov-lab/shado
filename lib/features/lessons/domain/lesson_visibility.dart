import '../../auth/domain/entities/auth_user.dart';

/// The `is_public` flag to send when [role] creates a lesson or a folder:
/// the owner picks it, a pro user always creates private ones, for others the
/// server decides.
bool? publicFlagForRole(UserRole? role, {required bool requested}) =>
    switch (role) {
      UserRole.owner => requested,
      UserRole.userPro => false,
      _ => null,
    };
