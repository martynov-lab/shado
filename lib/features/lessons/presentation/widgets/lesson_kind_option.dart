import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// A big tappable card for one lesson kind on the creation picker.
class LessonKindOption extends StatelessWidget {
  const LessonKindOption({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.rLg,
          child: AppCard(
            child: Row(
              children: [
                Icon(icon, size: AppSizes.iconLg, color: colors.primary),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppText.title.copyWith(color: colors.text),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        description,
                        style: AppText.caption.copyWith(color: colors.text3),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.text3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
