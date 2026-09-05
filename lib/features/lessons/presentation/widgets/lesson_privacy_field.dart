import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// The private lesson switch; shown to the owner only.
class LessonPrivacyField extends StatelessWidget {
  const LessonPrivacyField({
    super.key,
    required this.isPrivate,
    required this.onChanged,
  });

  final bool isPrivate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Приватный урок',
                style: AppText.title.copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                'Виден только вам, в общий каталог не попадёт',
                style: AppText.caption.copyWith(color: colors.text2),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        AppSwitch(
          value: isPrivate,
          onChanged: onChanged,
          semanticLabel: 'Приватный урок',
        ),
      ],
    );
  }
}
