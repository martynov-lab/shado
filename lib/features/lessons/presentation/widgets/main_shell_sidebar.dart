import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../pages/main_shell.dart';
import 'account_menu.dart';
import 'lesson_gradients.dart';
import 'main_shell_brand.dart';

/// Sidebar десктопа: бренд, вертикальное меню разделов, кнопка «Добавить урок»
/// и блок текущего пользователя внизу.
class MainShellSidebar extends ConsumerWidget {
  const MainShellSidebar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.canAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Показывать ли кнопку «Добавить урок».
  final bool canAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final email = ref.watch(
      authControllerProvider.select((state) => state.user?.email ?? ''),
    );

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
              _SidebarItem(
                destination: MainShell.destinations.first,
                selected: currentIndex == 0,
                onTap: () => onSelected(0),
              ),
              if (canAdd) ...[
                const SizedBox(height: AppSpacing.s5),
                AppButton(
                  label: 'Добавить урок',
                  icon: Icons.add_rounded,
                  expand: true,
                  onPressed: () => onSelected(MainShell.addIndex),
                ),
              ],
              const Spacer(),
              _SidebarUser(email: email),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final MainShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = selected ? colors.primary : colors.text2;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.rMd,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            decoration: BoxDecoration(
              color: selected ? colors.primarySoft : Colors.transparent,
              borderRadius: AppRadii.rMd,
            ),
            child: Row(
              children: [
                AppIcon(destination.icon, size: AppSizes.iconMd, color: tint),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  destination.label,
                  style: AppText.label.copyWith(color: tint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Блок пользователя: аватар, email и меню аккаунта (выход, раздел владельца).
class _SidebarUser extends StatelessWidget {
  const _SidebarUser({required this.email});

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
              email.isEmpty ? 'Аккаунт' : email,
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
