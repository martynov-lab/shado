import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'account_menu.dart';
import 'lesson_gradients.dart';

/// User block: avatar, email and the account menu.
class MainShellSidebarUser extends StatelessWidget {
  const MainShellSidebarUser({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s2),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: AppRadii.rMd,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: lessonBrandGradient(colors),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              email.isEmpty ? 'Account' : email,
              style: AppText.label.copyWith(color: colors.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const AccountMenu(),
        ],
      ),
    );
  }
}
