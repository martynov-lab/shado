import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Row of examples that wraps on narrow screens.
class GalleryWrap extends StatelessWidget {
  const GalleryWrap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.s3,
    runSpacing: AppSpacing.s3,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}
