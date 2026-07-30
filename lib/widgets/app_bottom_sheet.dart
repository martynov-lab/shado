import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Показывает модальный лист в оформлении Shadowing: верхние углы rXxl,
/// поверхность surface, тень e3.
///
/// Тень задаётся своим контейнером, а не `elevation`: материаловская тень
/// плоская и серая, а нам нужен фиолетовый подтон из [AppShadows].
///
/// ```dart
/// final speed = await showAppBottomSheet<double>(
///   context: context,
///   title: 'Скорость',
///   builder: (context) => const SpeedPicker(),
/// );
/// ```
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool showHandle = true,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  final colors = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    // Фон и тень рисует сам лист — стоковые здесь только помешали бы.
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: colors.surfaceInv.withValues(alpha: AppOpacities.scrim),
    builder: (context) =>
        _AppBottomSheet(title: title, showHandle: showHandle, child: builder(context)),
  );
}

class _AppBottomSheet extends StatelessWidget {
  const _AppBottomSheet({
    required this.child,
    required this.showHandle,
    this.title,
  });

  final Widget child;
  final bool showHandle;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

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
        color: c.surface,
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
                      color: c.borderStrong,
                      borderRadius: AppRadii.rPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
              ],
              if (title != null) ...[
                Text(title!, style: AppText.h2.copyWith(color: c.text)),
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
