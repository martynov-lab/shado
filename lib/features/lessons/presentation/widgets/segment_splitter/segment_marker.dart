import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Диаметр кружка на верхнем конце иглы и толщина её линии — общий язык с
/// метками границ на аудиодорожке.
const double kNeedleCircle = 14;
const double kNeedleLine = 3;

/// Стиль, которым символ-разделитель занимает место в тексте: сам «|» невидим —
/// метку поверх поля точно по его месту рисует игла [SegmentMarkerNeedle].
/// Небольшой [letterSpacing] оставляет зазор под линию иглы.
TextStyle markerTextStyle(TextStyle? base) {
  return (base ?? const TextStyle()).copyWith(
    color: const Color(0x00000000),
    letterSpacing: 3,
  );
}

/// Игла-метка: кружок на верхнем конце вертикальной линии. Тот же силуэт, что у
/// меток границ на аудиодорожке. Рисуется и как ручка поверх текста, и как
/// призрак/индикатор при перетаскивании.
class SegmentMarkerNeedle extends StatelessWidget {
  const SegmentMarkerNeedle({
    super.key,
    required this.height,
    required this.color,
    this.ringColor,
    this.opacity = 1,
  });

  /// Высота линии — обычно высота строки текста.
  final double height;

  final Color color;

  /// Обводка кружка под цвет поверхности, на которой лежит игла.
  final Color? ringColor;

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final ring = ringColor ?? context.colors.surface;
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: kNeedleCircle,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: kNeedleLine,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadii.rXs,
              ),
            ),
            // Кружок сидит на верхнем конце и наполовину выступает над строкой —
            // за него метку берут.
            Positioned(
              top: -kNeedleCircle / 2,
              child: Container(
                width: kNeedleCircle,
                height: kNeedleCircle,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: AppSizes.borderThick),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Чип-источник «Метка» в тулбаре: его перетаскивают в текст. Сам по себе
/// статичен — перетаскивание навешивает `Draggable` снаружи.
class SegmentMarkerChip extends StatelessWidget {
  const SegmentMarkerChip({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: enabled ? 1 : AppOpacities.disabled,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s2,
          AppSpacing.s4,
          AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: AppRadii.rPill,
          border: Border.all(color: colors.primary, width: AppSizes.borderThin),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: kNeedleCircle,
              height: 20,
              child: SegmentMarkerNeedle(
                height: 20,
                color: colors.primary,
                ringColor: colors.primarySoft,
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Text('Метка', style: AppText.label.copyWith(color: colors.primary)),
          ],
        ),
      ),
    );
  }
}

/// Призрак под пальцем во время перетаскивания метки.
class SegmentMarkerGhost extends StatelessWidget {
  const SegmentMarkerGhost({super.key});

  @override
  Widget build(BuildContext context) {
    return SegmentMarkerNeedle(
      height: 32,
      color: context.colors.primary,
      ringColor: context.colors.surface,
    );
  }
}
