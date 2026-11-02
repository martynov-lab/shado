import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// One star of a rating: filled or outlined.
class AppStar extends StatelessWidget {
  const AppStar({super.key, required this.filled, required this.size});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Icon(
      filled ? Icons.star_rounded : Icons.star_outline_rounded,
      size: size,
      color: filled ? colors.warning : colors.text3,
    );
  }
}
