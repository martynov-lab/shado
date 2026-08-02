import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Шапка экрана прогресса: заголовок «Прогресс» и, по желанию, аватар справа.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, this.showAvatar = true});

  /// Показать аватар пользователя справа (в узких раскладках; на десктопе
  /// профиль живёт в sidebar каркаса).
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Text('Прогресс', style: AppText.h2.copyWith(color: colors.text)),
        ),
        if (showAvatar)
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppBrand.signGradient,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
