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
      title: 'Списки и карточки',
      caption: 'Строка урока и карточка-контейнер',
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
                  subtitle: 'Повседневное общение · 12 сегментов',
                  trailingTime: '04:17',
                  selected: true,
                  semanticLabel: 'Урок 1, Small talk at the airport, играет',
                  onTap: () {},
                ),
                AppListRow(
                  index: 2,
                  title: 'Ordering coffee',
                  subtitle: 'Повседневное общение · 8 сегментов',
                  trailingTime: '02:48',
                  onTap: () {},
                ),
                AppListRow(
                  index: 3,
                  title: 'Job interview basics',
                  subtitle: 'Деловой английский · 21 сегмент',
                  trailing: const AppBadge(
                    label: 'Новый',
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
            semanticLabel: 'Карточка прогресса',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Нажимаемая карточка',
                        style: AppText.h2.copyWith(color: colors.text),
                      ),
                    ),
                    const AppBadge(
                      label: 'Серия 7 дней',
                      variant: AppBadgeVariant.hot,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  'На наведении поднимается с тени e1 до e2, с клавиатуры '
                  'получает кольцо фокуса.',
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
