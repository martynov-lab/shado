import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Form divider: rule, caption, rule.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
          child: Text(
            label,
            style: AppText.caption.copyWith(color: context.colors.text3),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
