import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Карточка-секция редактора: заголовок с приглушённым уточнением, необязательная
/// строка-подсказка и содержимое. Одинаково оформляет блоки «Аудио» и «Текст».
class LessonSectionCard extends StatelessWidget {
  const LessonSectionCard({
    super.key,
    required this.label,
    required this.child,
    this.note,
    this.hint,
  });

  final String label;

  /// Приглушённое уточнение рядом с заголовком, например «— разбей на сегменты».
  final String? note;

  /// Пояснение под заголовком мелким шрифтом.
  final String? hint;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              style: AppText.title.copyWith(color: colors.text),
              children: [
                TextSpan(text: label),
                if (note != null)
                  TextSpan(
                    text: '  $note',
                    style: AppText.caption.copyWith(color: colors.text3),
                  ),
              ],
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              hint!,
              style: AppText.caption.copyWith(color: colors.text3),
            ),
          ],
          const SizedBox(height: AppSpacing.s4),
          child,
        ],
      ),
    );
  }
}
