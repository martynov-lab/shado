import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Карточка раздела главного экрана: заголовок с необязательной подписью справа
/// и произвольное содержимое под ним.
///
/// Обёртка над [AppCard] — чтобы карточки цели недели, активности и минут
/// держали один заголовок и отступ.
class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.title,
    required this.child,
    this.caption,
  });

  final String title;

  /// Подпись у правого края заголовка — например «эта неделя».
  final String? caption;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.title.copyWith(color: colors.text),
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: AppText.caption.copyWith(color: colors.text3),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          child,
        ],
      ),
    );
  }
}
