import 'package:flutter/material.dart';

/// Waveform placeholder while the file uploads or no audio is chosen.
class WaveformPlaceholderCard extends StatelessWidget {
  const WaveformPlaceholderCard({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: SizedBox(
      height: height,
      child: Center(child: child),
    ),
  );
}
