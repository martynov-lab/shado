import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

import 'segment_marker.dart';

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
            Text(
              'Marker',
              style: AppText.label.copyWith(color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
