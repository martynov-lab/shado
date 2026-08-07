import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../widgets/completion_threshold_section.dart';
import '../widgets/users_admin_section.dart';

/// Вкладка «Управление» — раздел владельца. Пока внутри один блок,
/// «Пользователи»; на следующем этапе рядом встанет «Порог пройденности».
///
/// Каркас (Scaffold, навигация) даёт [MainShell]; здесь — только содержимое
/// вкладки.
class ManagementPage extends StatelessWidget {
  const ManagementPage({super.key});

  static const String routePath = '/manage';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s3,
            ),
            child: Text(
              'Управление',
              style: AppText.h2.copyWith(color: colors.text),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5),
            child: CompletionThresholdSection(),
          ),
          const SizedBox(height: AppSpacing.s5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
            child: Text(
              'Пользователи',
              style: AppText.label.copyWith(color: colors.text2),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          const Expanded(child: UsersAdminSection()),
        ],
      ),
    );
  }
}
