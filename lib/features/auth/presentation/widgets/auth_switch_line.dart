import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'auth_link.dart';

/// Switch between sign-in and sign-up at the bottom of the form.
class AuthSwitchLine extends StatelessWidget {
  const AuthSwitchLine({
    super.key,
    required this.isRegistration,
    required this.onPressed,
  });

  final bool isRegistration;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            isRegistration ? 'Уже есть аккаунт?' : 'Нет аккаунта?',
            style: AppText.caption.copyWith(color: context.colors.text3),
          ),
        ),
        AuthLink(
          label: isRegistration ? 'Войти' : 'Зарегистрироваться',
          onPressed: onPressed,
        ),
      ],
    );
  }
}
