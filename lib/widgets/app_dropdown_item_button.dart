import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_dropdown.dart';

/// Menu row on [MenuItemButton] — it handles arrow keys and Esc.
class AppDropdownItemButton<T> extends StatelessWidget {
  const AppDropdownItemButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final AppDropdownItem<T> item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MenuItemButton(
      onPressed: onPressed,
      leadingIcon: item.icon == null
          ? null
          : Icon(
              item.icon,
              size: AppSizes.iconMd,
              color: selected ? colors.primary : colors.text2,
            ),
      trailingIcon: selected
          ? Icon(
              Icons.check_rounded,
              size: AppSizes.iconMd,
              color: colors.primary,
            )
          : null,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(0, AppSizes.minTouchTarget),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadii.rSm),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colors.primary.withValues(alpha: AppOpacities.press);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colors.primary.withValues(alpha: AppOpacities.hover);
          }
          return selected ? colors.primarySoft : Colors.transparent;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(AppText.body),
        foregroundColor: WidgetStatePropertyAll(
          selected ? colors.primary : colors.text,
        ),
      ),
      child: Text(item.label, overflow: TextOverflow.ellipsis),
    );
  }
}
