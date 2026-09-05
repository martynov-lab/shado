import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Section header: title on the left and an action link on the right.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppText.title.copyWith(color: colors.text)),
        ),
        Semantics(
          button: true,
          label: actionLabel,
          excludeSemantics: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onAction,
              borderRadius: AppRadii.rSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s2,
                  vertical: AppSpacing.s1,
                ),
                child: Text(
                  actionLabel,
                  style: AppText.label.copyWith(color: colors.primary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
