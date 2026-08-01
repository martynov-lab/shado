import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'auth_brand_panel.dart';

/// Десктоп: брендовая панель слева, форма справа.
class AuthDesktopLayout extends StatelessWidget {
  const AuthDesktopLayout({
    super.key,
    required this.form,
    required this.isRegistration,
  });

  final Widget form;
  final bool isRegistration;

  /// Пропорция колонок из макета — 44% под панель.
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
