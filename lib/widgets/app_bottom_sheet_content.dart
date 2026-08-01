import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Поверхность модального листа: скруглённая шапка, ручка, заголовок и тень e3.
///
/// Показывают его через `showAppBottomSheet`, но виджет публичный: так лист
/// можно собрать и вручную — например, в витрине компонентов.
class AppBottomSheetContent extends StatelessWidget {
  const AppBottomSheetContent({
    super.key,
    required this.child,
    this.showHandle = true,
    this.title,
  });

  final Widget child;

  /// Полоска-ручка сверху: подсказка, что лист тянется.
  final bool showHandle;

  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      // На планшете и десктопе лист не растягивается на всю ширину — читать
      // строку в 1400 px невозможно.
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
            // Клавиатура не должна закрывать содержимое листа.
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
