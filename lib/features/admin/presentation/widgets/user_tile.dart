import 'package:flutter/material.dart';

import '../../../auth/domain/entities/auth_user.dart';

/// Пользователь в списке админки: кто он и переключатель роли.
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.isSelf,
    required this.onRoleChanged,
  });

  final AuthUser user;

  /// Это сам вошедший: подписываем строку, чтобы он видел, кого понижает.
  final bool isSelf;

  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          user.isOwner ? Icons.shield_outlined : Icons.person_outline,
        ),
      ),
      title: Text(user.email, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        isSelf ? 'это вы · ${user.role.name}' : user.role.name,
        style: theme.textTheme.bodySmall,
      ),
      trailing: SegmentedButton<UserRole>(
        segments: const [
          ButtonSegment(value: UserRole.user, label: Text('user')),
          ButtonSegment(value: UserRole.owner, label: Text('owner')),
        ],
        selected: {user.role},
        showSelectedIcon: false,
        onSelectionChanged: (roles) => onRoleChanged(roles.first),
      ),
    );
  }
}
