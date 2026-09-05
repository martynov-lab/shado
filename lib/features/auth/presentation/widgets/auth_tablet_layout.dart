import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'auth_brand_header.dart';

/// Tablet: a centered card with a brand header and the form below.
class AuthTabletLayout extends StatelessWidget {
  const AuthTabletLayout({
    super.key,
    required this.form,
    required this.isRegistration,
  });

  final Widget form;
  final bool isRegistration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return CustomScrollView(
      slivers: [
        // The card is centered and scrolls away in a short window.
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.overlayMaxWidth,
                ),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppRadii.rXxl,
                    border: Border.all(
                      color: colors.border,
                      width: AppSizes.borderThin,
                    ),
                    boxShadow: context.shadows.e2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // The header and the form stretch to the full card width.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthBrandHeader(isRegistration: isRegistration),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.s6),
                        child: form,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
