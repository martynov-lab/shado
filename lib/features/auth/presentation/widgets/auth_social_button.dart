import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Кнопка входа через сервис.
///
/// Без [onPressed] кнопка выглядит обычно, но ничего не делает: входа через
/// Google и Apple в приложении пока нет.
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final AppIcons icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.rMd,
          side: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.rMd,
          child: SizedBox(
            height: AppSizes.controlMd,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(icon, size: AppSizes.iconMd, color: colors.text),
                const SizedBox(width: AppSpacing.s2),
                Flexible(
                  child: Text(
                    label,
                    style: AppText.label.copyWith(color: colors.text),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
