import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Подпись над группой примеров внутри раздела.
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
