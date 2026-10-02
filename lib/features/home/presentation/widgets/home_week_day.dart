import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// One day of the practice week: a dot and the weekday.
class HomeWeekDay extends StatelessWidget {
  const HomeWeekDay({
    super.key,
    required this.label,
    required this.done,
    required this.today,
  });

  final String label;
  final bool done;
  final bool today;

  static const double _size = 28;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: done ? colors.primary : colors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: today || done ? colors.primary : colors.border,
              width: today ? AppSizes.borderThick : AppSizes.borderThin,
            ),
          ),
          child: done
              ? Center(
                  child: AppIcon(
                    AppIcons.check,
                    size: AppSizes.iconSm,
                    color: colors.primaryOn,
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(label, style: AppText.caption.copyWith(color: colors.text3)),
      ],
    );
  }
}
