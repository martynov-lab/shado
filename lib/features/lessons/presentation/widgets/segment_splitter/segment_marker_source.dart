import 'package:flutter/material.dart';

import 'segment_marker_chip.dart';
import 'segment_marker_drag.dart';
import 'segment_marker_ghost.dart';

/// Source chip: a tap enters placement mode, a drag drops a marker.
class SegmentMarkerSource extends StatelessWidget {
  const SegmentMarkerSource({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SegmentMarkerChip(enabled: false);
    return GestureDetector(
      onTap: onTap,
      child: Draggable<SegmentMarkerDrag>(
        data: const SegmentMarkerDrag(null),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: const SegmentMarkerGhost(),
        childWhenDragging: const SegmentMarkerChip(enabled: false),
        child: const SegmentMarkerChip(),
      ),
    );
  }
}
