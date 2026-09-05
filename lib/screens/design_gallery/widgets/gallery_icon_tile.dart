import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Gallery tile: an icon and its name in the set.
class GalleryIconTile extends StatelessWidget {
  const GalleryIconTile(this.icon, {super.key});

  final AppIcons icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: AppSizes.iconLg, color: colors.text),
        const SizedBox(height: AppSpacing.s2),
        Text(
          icon.fileName,
          style: AppText.caption.copyWith(color: colors.text3),
        ),
      ],
    );
  }
}
