import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

import 'segment_marker.dart';

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
