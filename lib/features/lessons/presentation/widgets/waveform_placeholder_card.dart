import 'package:flutter/material.dart';

/// Место волны, пока её нет: ждём загрузку файла или ещё не выбрали аудио.
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
