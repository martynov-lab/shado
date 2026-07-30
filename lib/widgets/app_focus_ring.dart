import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Кольцо фокуса с клавиатуры.
///
/// Рисуется тенью с нулевым размытием и положительным `spreadRadius`, поэтому
/// не занимает места и не сдвигает соседей — обводка появляется снаружи
/// контрола, а раскладка остаётся прежней.
///
/// Показывать его должен сам контрол: он знает, пришёл фокус с клавиатуры
/// или это просто тап (см. [AppFocusRing.isKeyboardFocus]).
class AppFocusRing extends StatelessWidget {
  const AppFocusRing({
    super.key,
    required this.visible,
    required this.borderRadius,
    required this.child,
  });

  final bool visible;
  final BorderRadius borderRadius;
  final Widget child;

  /// Фокус пришёл с клавиатуры (а не по тапу) — только тогда кольцо уместно.
  static bool get isKeyboardFocus =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: context.motion(AppDurations.fast),
      curve: AppCurves.standard,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: visible
            ? [
                BoxShadow(
                  color: context.colors.primary.withValues(
                    alpha: AppOpacities.focusRing,
                  ),
                  spreadRadius: AppSizes.focusRing,
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }
}
