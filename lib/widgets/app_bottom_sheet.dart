import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_bottom_sheet_content.dart';

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
    builder: (context) => AppBottomSheetContent(
      title: title,
      showHandle: showHandle,
      child: builder(context),
    ),
  );
}
