import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../screens/main_shell/main_shell.dart';
import 'main_shell_brand.dart';
import 'main_shell_sidebar_item.dart';
import 'main_shell_sidebar_user.dart';

/// Desktop sidebar: brand, section menu, the add button and the profile.
class MainShellSidebar extends StatelessWidget {
  const MainShellSidebar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.canAdd,
    required this.email,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Whether to show the add-lesson button.
  final bool canAdd;

  /// The signed-in user shown at the bottom.
  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                child: MainShellBrand(showLabel: true, size: 38),
              ),
              const SizedBox(height: AppSpacing.s6),
              for (final i in MainShell.sectionIndexes) ...[
                MainShellSidebarItem(
                  destination: MainShell.destinations[i],
                  selected: currentIndex == i,
                  onTap: () => onSelected(i),
                ),
                const SizedBox(height: AppSpacing.s1),
              ],
              if (canAdd) ...[
                const SizedBox(height: AppSpacing.s4),
                AppButton(
                  label: 'Add lesson',
                  icon: Icons.add_rounded,
                  expand: true,
                  onPressed: () => onSelected(MainShell.addIndex),
                ),
              ],
              const Spacer(),
              MainShellSidebarUser(email: email),
            ],
          ),
        ),
      ),
    );
  }
}
