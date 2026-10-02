import 'package:flutter/material.dart';

import 'segment_marker.dart';
import 'segment_marker_drag.dart';

/// Needle handle over the text: a drag moves the marker, a tap removes it.
class SegmentMarkerPin extends StatelessWidget {
  const SegmentMarkerPin({
    super.key,
    required this.markerIndex,
    required this.number,
    required this.height,
    required this.color,
    required this.ringColor,
    required this.onDelete,
  });

  /// Index of the marker character in the text.
  final int markerIndex;

  /// Marker number shown inside the dot.
  final int number;
  final double height;
  final Color color;
  final Color ringColor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Draggable<SegmentMarkerDrag>(
      data: SegmentMarkerDrag(markerIndex),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: SegmentMarkerNeedle(height: height, color: color),
      childWhenDragging: const SizedBox.shrink(),
      onDraggableCanceled: (_, _) => onDelete(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDelete,
        child: Center(
          child: SegmentMarkerNeedle(
            height: height,
            color: color,
            ringColor: ringColor,
            number: number,
          ),
        ),
      ),
    );
  }
}
