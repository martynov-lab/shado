import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/widgets/gallery_label.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_wrap.dart';
import 'package:shado/widgets/widgets.dart';

/// Раздел витрины: чипы, фильтры и бейджи.
class GalleryChipsSection extends StatefulWidget {
  const GalleryChipsSection({super.key});

  @override
  State<GalleryChipsSection> createState() => _GalleryChipsSectionState();
}

class _GalleryChipsSectionState extends State<GalleryChipsSection> {
  static const _tags = ['Идиомы', 'Произношение', 'Аудирование', 'Бизнес'];

  final Set<String> _filters = {'Идиомы'};

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Чипы и бейджи',
    caption: 'Ярлыки, фильтры и статусы',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GalleryLabel('Чипы — заливка primary и мягкая'),
        GalleryWrap(
          children: [
            AppChip(label: 'Выбран', selected: true, onTap: () {}),
            AppChip(
              label: 'Выбран мягко',
              selected: true,
              style: AppChipStyle.onSoft,
              onTap: () {},
            ),
            AppChip(label: 'Не выбран', onTap: () {}),
            AppChip(
              label: 'С иконкой',
              icon: Icons.local_fire_department_rounded,
              onTap: () {},
            ),
            const AppChip(label: 'Просто ярлык'),
          ],
        ),
        const GalleryLabel('Фильтры — множественный выбор'),
        GalleryWrap(
          children: [
            for (final tag in _tags)
              AppFilterChip(
                label: tag,
                selected: _filters.contains(tag),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _filters.add(tag);
                  } else {
                    _filters.remove(tag);
                  }
                }),
              ),
          ],
        ),
        const GalleryLabel('Бейджи'),
        const GalleryWrap(
          children: [
            AppBadge(label: 'Новый', icon: Icons.auto_awesome_rounded),
            AppBadge(
              label: 'Пора повторить',
              variant: AppBadgeVariant.due,
              icon: Icons.schedule_rounded,
            ),
            AppBadge(
              label: 'Серия 7 дней',
              variant: AppBadgeVariant.hot,
              icon: Icons.local_fire_department_rounded,
            ),
          ],
        ),
      ],
    ),
  );
}
