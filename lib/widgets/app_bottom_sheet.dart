import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_bottom_sheet_content.dart';

/// Shows a modal sheet styled by the design system.
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
    // The sheet paints its own background and shadow.
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
