import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Diameter of the dot at the needle top and the line thickness.
const double kNeedleCircle = 14;
const double kNeedleLine = 3;

/// Style of the invisible delimiter: it leaves room for the needle.
TextStyle markerTextStyle(TextStyle? base) {
  return (base ?? const TextStyle()).copyWith(
    color: const Color(0x00000000),
    letterSpacing: 3,
  );
}

/// Marker needle: a dot at the top of a vertical line.
class SegmentMarkerNeedle extends StatelessWidget {
  const SegmentMarkerNeedle({
    super.key,
    required this.height,
    required this.color,
    this.ringColor,
    this.opacity = 1,
    this.number,
  });

  /// Line height, usually the height of a text line.
  final double height;

  final Color color;

  /// Dot ring painted in the color of the surface under the needle.
  final Color? ringColor;

  final double opacity;

  /// Marker number inside the dot; `null` leaves the dot blank.
  final int? number;

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
            // The dot sticks out above the line and is the grab handle.
            Positioned(
              top: -kNeedleCircle / 2,
              child: Container(
                width: kNeedleCircle,
                height: kNeedleCircle,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: AppSizes.borderThick),
                ),
                child: number == null
                    ? null
                    : Text(
                        '$number',
                        style: TextStyle(
                          color: ring,
                          fontSize: 9,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Source marker chip dragged into the text.
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

/// Ghost under the finger while a marker is dragged.
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
