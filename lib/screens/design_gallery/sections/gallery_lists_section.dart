import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Gallery section: list rows and cards.
class GalleryListsSection extends StatelessWidget {
  const GalleryListsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GallerySection(
      title: 'Lists and cards',
      caption: 'Lesson row and container card',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Column(
              children: [
                AppListRow(
                  index: 1,
                  title: 'Small talk at the airport',
                  subtitle: 'Everyday conversation · 12 segments',
                  trailingTime: '04:17',
                  selected: true,
                  semanticLabel: 'Lesson 1, Small talk at the airport, playing',
                  onTap: () {},
                ),
                AppListRow(
                  index: 2,
                  title: 'Ordering coffee',
                  subtitle: 'Everyday conversation · 8 segments',
                  trailingTime: '02:48',
                  onTap: () {},
                ),
                AppListRow(
                  index: 3,
                  title: 'Job interview basics',
                  subtitle: 'Business English · 21 segments',
                  trailing: const AppBadge(
                    label: 'New',
                    variant: AppBadgeVariant.fresh,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          AppCard(
            onTap: () {},
            semanticLabel: 'Progress card',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tappable card',
                        style: AppText.h2.copyWith(color: colors.text),
                      ),
                    ),
                    const AppBadge(
                      label: '7-day streak',
                      variant: AppBadgeVariant.hot,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  'On hover it rises from shadow e1 to e2, from the keyboard '
                  'it gets a focus ring.',
                  style: AppText.body.copyWith(color: colors.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
