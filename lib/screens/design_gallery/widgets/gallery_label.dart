import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Caption above a group of examples inside a section.
class GalleryLabel extends StatelessWidget {
  const GalleryLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.s5, bottom: AppSpacing.s3),
    child: Text(
      text.toUpperCase(),
      style: AppText.caption.copyWith(color: context.colors.text3),
    ),
  );
}
