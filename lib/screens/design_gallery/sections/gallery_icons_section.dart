import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/widgets/gallery_icon_tile.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_label.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_wrap.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Gallery section: the icon set and how it is tinted.
class GalleryIconsSection extends StatelessWidget {
  const GalleryIconsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GallerySection(
      title: 'Icons',
      caption: 'SVG set from the mockups, ${AppIcons.values.length} icons',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GalleryLabel('Sizes — sm, md, lg'),
          const GalleryWrap(
            children: [
              AppIcon(AppIcons.headphones, size: AppSizes.iconSm),
              AppIcon(AppIcons.headphones, size: AppSizes.iconMd),
              AppIcon(AppIcons.headphones, size: AppSizes.iconLg),
            ],
          ),
          const GalleryLabel('Color — any theme token'),
          GalleryWrap(
            children: [
              AppIcon(
                AppIcons.flame,
                size: AppSizes.iconLg,
                color: colors.accent,
              ),
              AppIcon(
                AppIcons.check,
                size: AppSizes.iconLg,
                color: colors.success,
              ),
              AppIcon(
                AppIcons.clock,
                size: AppSizes.iconLg,
                color: colors.warning,
              ),
              AppIcon(
                AppIcons.trash,
                size: AppSizes.iconLg,
                color: colors.danger,
              ),
              AppIcon(
                AppIcons.globe,
                size: AppSizes.iconLg,
                color: colors.text3,
              ),
              // The logo keeps brand colors even with an explicit tint.
              AppIcon(
                AppIcons.brandGoogle,
                size: AppSizes.iconLg,
                color: colors.danger,
              ),
            ],
          ),
          const GalleryLabel('Full set — the name under an icon = the name in code'),
          GalleryWrap(
            children: [
              for (final icon in AppIcons.values) GalleryIconTile(icon),
            ],
          ),
        ],
      ),
    );
  }
}
