import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';


/// Desktop filter sidebar: every checkbox group at once.
class LessonsFilterPanel extends StatelessWidget {
  const LessonsFilterPanel({
    super.key,
    required this.activeCount,
    required this.onClear,
    required this.options,
  });

  /// The reset button shows while something is selected.
  final int activeCount;

  final VoidCallback onClear;
  final Widget options;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: colors.surface2,
        border: Border(
          left: BorderSide(color: colors.border, width: AppSizes.borderThin),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filters',
                    style: AppText.title.copyWith(color: colors.text),
                  ),
                ),
                if (activeCount > 0)
                  Semantics(
                    button: true,
                    child: InkWell(
                      onTap: onClear,
                      borderRadius: AppRadii.rSm,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s1),
                        child: Text(
                          'Reset',
                          style: AppText.label.copyWith(color: colors.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s5),
            options,
          ],
        ),
      ),
    );
  }
}
