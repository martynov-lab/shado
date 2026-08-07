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
        isSelf ? 'это вы · ${user.role.wire}' : user.role.wire,
        style: theme.textTheme.bodySmall,
      ),
      // Ролей четыре — в trailing помещается только выпадающий список, а не
      // сегменты.
      trailing: DropdownButton<UserRole>(
        value: user.role,
        underline: const SizedBox.shrink(),
        items: [
          for (final role in UserRole.values)
            DropdownMenuItem(value: role, child: Text(role.wire)),
        ],
        onChanged: (role) {
          if (role != null) onRoleChanged(role);
        },
      ),
    );
  }
}
