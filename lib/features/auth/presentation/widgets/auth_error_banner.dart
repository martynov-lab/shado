import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Sign-in or sign-up error message above the form button.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          color: colors.dangerSoft,
          borderRadius: AppRadii.rMd,
        ),
        child: Text(
          message,
          style: AppText.label.copyWith(color: colors.danger),
        ),
      ),
    );
  }
}
