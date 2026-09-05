import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'auth_brand_panel.dart';

/// Desktop: brand panel on the left, form on the right.
class AuthDesktopLayout extends StatelessWidget {
  const AuthDesktopLayout({
    super.key,
    required this.form,
    required this.isRegistration,
  });

  final Widget form;
  final bool isRegistration;

  /// Column ratio from the design — 44% for the panel.
  static const int _brandFlex = 44;
  static const int _formFlex = 56;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: _brandFlex,
        child: AuthBrandPanel(isRegistration: isRegistration),
      ),
      Expanded(
        flex: _formFlex,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.overlayMaxWidth,
                    ),
                    child: form,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
