import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Settings section: a title and a card with rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.s1,
            bottom: AppSpacing.s2,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppText.caption.copyWith(
              color: colors.text3,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: AppSizes.borderThin,
                    thickness: AppSizes.borderThin,
                    color: colors.border,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
