/// Marker drag payload; a `null` [fromMarkerIndex] means a new marker.
class SegmentMarkerDrag {
  const SegmentMarkerDrag(this.fromMarkerIndex);

  final int? fromMarkerIndex;
}
