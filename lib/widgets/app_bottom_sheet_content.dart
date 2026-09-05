import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Modal sheet surface: rounded top, handle, title and shadow.
class AppBottomSheetContent extends StatelessWidget {
  const AppBottomSheetContent({
    super.key,
    required this.child,
    this.showHandle = true,
    this.title,
  });

  final Widget child;

  /// Whether to show the handle on top.
  final bool showHandle;

  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      // On wide screens the sheet does not stretch full width.
      constraints: BoxConstraints(
        maxWidth: context.responsive(
          mobile: double.infinity,
          tablet: AppBreakpoints.tablet,
        ),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xxl),
        ),
        boxShadow: context.shadows.e3,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.s6,
            right: AppSpacing.s6,
            top: AppSpacing.s3,
            // Padding for the keyboard.
            bottom: AppSpacing.s6 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle) ...[
                Center(
                  child: Container(
                    width: AppSizes.sheetHandleWidth,
                    height: AppSizes.sheetHandleHeight,
                    decoration: BoxDecoration(
                      color: colors.borderStrong,
                      borderRadius: AppRadii.rPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
              ],
              if (title case final text?) ...[
                Text(text, style: AppText.h2.copyWith(color: colors.text)),
                const SizedBox(height: AppSpacing.s4),
              ],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
