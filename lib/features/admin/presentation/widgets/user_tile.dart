import 'package:flutter/material.dart';

import '../../../auth/domain/entities/auth_user.dart';

/// User row in the admin list: who they are and a role picker.
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.isSelf,
    required this.onRoleChanged,
  });

  final AuthUser user;

  /// This is the signed-in user — the row gets a caption.
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
      // With four roles only a dropdown fits into the trailing slot.
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
