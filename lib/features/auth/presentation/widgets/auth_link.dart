import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Текстовая ссылка формы: «Забыли пароль?», «Зарегистрироваться».
///
/// Без [onPressed] ссылка остаётся видимой, но не нажимается: так выглядят
/// пункты макета, за которыми ещё нет действия.
class AuthLink extends StatelessWidget {
  const AuthLink({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AppTapTarget(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadii.rSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s2,
                vertical: AppSpacing.s1,
              ),
              child: Text(
                label,
                style: AppText.label.copyWith(color: context.colors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
