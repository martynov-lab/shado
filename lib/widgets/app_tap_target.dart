import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:shado/theme/theme.dart';

/// Расширяет область нажатия ребёнка до [minSize], не меняя его отрисовку.
///
/// Чекбокс рисуется 22×22, но попасть по нему пальцем нужно в 48×48. Обычный
/// `Padding` сдвинул бы картинку, поэтому здесь ребёнок остаётся по центру
/// своего размера, а хит-тест ловит промахи вокруг него.
class AppTapTarget extends SingleChildRenderObjectWidget {
  const AppTapTarget({
    super.key,
    super.child,
    this.minSize = const Size.square(AppSizes.minTouchTarget),
  });

  final Size minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTapTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderTapTarget).minSize = minSize;
  }
}

class _RenderTapTarget extends RenderShiftedBox {
  _RenderTapTarget(this._minSize) : super(null);

  Size _minSize;

  Size get minSize => _minSize;

  set minSize(Size value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = Size.zero;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(
        math.max(child.size.width, minSize.width),
        math.max(child.size.height, minSize.height),
      ),
    );
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null) return false;
    // Промах мимо ребёнка, но внутри расширенной зоны — сводим удар к его
    // центру, чтобы сработал тот же обработчик.
    final center =
        child.size.center(Offset.zero) +
        (child.parentData! as BoxParentData).offset;
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child.hitTest(result, position: center),
    );
  }
}
