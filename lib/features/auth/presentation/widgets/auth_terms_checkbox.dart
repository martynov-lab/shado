import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Согласие с условиями при регистрации. Названия документов выделены цветом,
/// но не открываются: самих страниц в приложении ещё нет.
class AuthTermsCheckbox extends StatelessWidget {
  const AuthTermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final linkStyle = AppText.caption.copyWith(
      color: colors.primary,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        AppCheckbox(
          value: value,
          onChanged: onChanged,
          semanticLabel: 'Принимаю условия использования',
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppText.caption.copyWith(color: colors.text2),
              children: [
                const TextSpan(text: 'Принимаю '),
                TextSpan(text: 'условия использования', style: linkStyle),
                const TextSpan(text: ' и '),
                TextSpan(text: 'политику конфиденциальности', style: linkStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
