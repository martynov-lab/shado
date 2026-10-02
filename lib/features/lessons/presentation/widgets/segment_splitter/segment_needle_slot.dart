import 'package:flutter/widgets.dart';

import 'segment_marker.dart';

/// Positions a needle or its handle by the marker caret rectangle.
class SegmentNeedleSlot extends StatelessWidget {
  const SegmentNeedleSlot({
    super.key,
    required this.rect,
    required this.color,
    this.opacity = 1,
    this.hitWidth = kNeedleCircle,
    this.pin,
  });

  final Rect rect;
  final Color color;
  final double opacity;
  final double hitWidth;

  /// Interactive handle shown instead of the plain needle.
  final Widget? pin;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left - hitWidth / 2,
      top: rect.top,
      width: hitWidth,
      height: rect.height,
      child:
          pin ??
          IgnorePointer(
            child: SegmentMarkerNeedle(
              height: rect.height,
              color: color,
              opacity: opacity,
            ),
          ),
    );
  }
}
