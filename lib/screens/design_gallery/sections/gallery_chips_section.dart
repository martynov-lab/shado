import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/widgets/gallery_label.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_wrap.dart';
import 'package:shado/widgets/widgets.dart';

/// Gallery section: chips, filters and badges.
class GalleryChipsSection extends StatefulWidget {
  const GalleryChipsSection({super.key});

  @override
  State<GalleryChipsSection> createState() => _GalleryChipsSectionState();
}

class _GalleryChipsSectionState extends State<GalleryChipsSection> {
  static const _tags = ['Idioms', 'Pronunciation', 'Listening', 'Business'];

  final Set<String> _filters = {'Idioms'};

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Chips and badges',
    caption: 'Labels, filters and statuses',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GalleryLabel('Chips — primary and soft fill'),
        GalleryWrap(
          children: [
            AppChip(label: 'Selected', selected: true, onTap: () {}),
            AppChip(
              label: 'Selected soft',
              selected: true,
              style: AppChipStyle.onSoft,
              onTap: () {},
            ),
            AppChip(label: 'Not selected', onTap: () {}),
            AppChip(
              label: 'With icon',
              icon: Icons.local_fire_department_rounded,
              onTap: () {},
            ),
            const AppChip(label: 'Plain label'),
          ],
        ),
        const GalleryLabel('Filters — multiple choice'),
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
        const GalleryLabel('Badges'),
        const GalleryWrap(
          children: [
            AppBadge(label: 'New', icon: Icons.auto_awesome_rounded),
            AppBadge(
              label: 'Time to review',
              variant: AppBadgeVariant.due,
              icon: Icons.schedule_rounded,
            ),
            AppBadge(
              label: '7-day streak',
              variant: AppBadgeVariant.hot,
              icon: Icons.local_fire_department_rounded,
            ),
          ],
        ),
      ],
    ),
  );
}
