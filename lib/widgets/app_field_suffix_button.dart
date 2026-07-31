import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Нажимаемая иконка справа внутри поля ввода: «показать пароль», «очистить».
class AppFieldSuffixButton extends StatelessWidget {
  const AppFieldSuffixButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onPressed,
        radius: AppSizes.iconLg,
        child: Icon(icon, size: AppSizes.iconMd, color: c.text2),
      ),
    );
  }
}
