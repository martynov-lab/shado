import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/widgets/gallery_icon_tile.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_label.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_wrap.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Раздел витрины: набор иконок Shadowing и то, как он красится.
class GalleryIconsSection extends StatelessWidget {
  const GalleryIconsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GallerySection(
      title: 'Иконки',
      caption: 'SVG-набор из макетов, ${AppIcons.values.length} штуки',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GalleryLabel('Размеры — sm, md, lg'),
          const GalleryWrap(
            children: [
              AppIcon(AppIcons.headphones, size: AppSizes.iconSm),
              AppIcon(AppIcons.headphones, size: AppSizes.iconMd),
              AppIcon(AppIcons.headphones, size: AppSizes.iconLg),
            ],
          ),
          const GalleryLabel('Цвет — любой токен темы'),
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
              // Логотип остаётся фирменным даже с явным цветом.
              AppIcon(
                AppIcons.brandGoogle,
                size: AppSizes.iconLg,
                color: colors.danger,
              ),
            ],
          ),
          const GalleryLabel('Весь набор — имя под иконкой = имя в коде'),
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
