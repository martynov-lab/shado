import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'auth_brand_row.dart';
import 'auth_brand_surface.dart';

/// Phone: a full-width brand strip on a gradient with the form below.
class AuthMobileLayout extends StatelessWidget {
  const AuthMobileLayout({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full-width brand strip on a gradient.
        const AuthBrandSurface(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s8,
            AppSpacing.s5,
            AppSpacing.s6,
          ),
          child: AuthBrandRow(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s6,
            AppSpacing.s5,
            AppSpacing.s8,
          ),
          child: form,
        ),
      ],
    ),
  );
}
