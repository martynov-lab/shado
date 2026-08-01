import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Шапка списка уроков: «Уроки · N» и произвольный элемент справа (аватар или
/// кнопка «Добавить»).
class LessonsHeader extends StatelessWidget {
  const LessonsHeader({super.key, required this.count, this.trailing});

  final int count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Уроки',
                  style: AppText.h2.copyWith(color: colors.text),
                ),
                TextSpan(
                  text: '  · $count',
                  style: AppText.title.copyWith(color: colors.text3),
                ),
              ],
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
