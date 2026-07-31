import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/theme/theme.dart';

/// Раздел витрины: шкала типографики.
class GalleryTypographySection extends StatelessWidget {
  const GalleryTypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GallerySection(
      title: 'Типографика',
      caption:
          'Sora для заголовков, Plus Jakarta Sans для текста, '
          'JetBrains Mono для цифр',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display 40/800',
            style: AppText.displayLg.copyWith(color: c.text),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text('Heading 1 — 28/700', style: AppText.h1.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.s2),
          Text('Heading 2 — 22/600', style: AppText.h2.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.s2),
          Text('Title — 17/700', style: AppText.title.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Body — 15/400. Shadowing — это когда ты повторяешь за диктором '
            'почти одновременно с ним.',
            style: AppText.body.copyWith(color: c.text2),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text('LABEL — 13/600', style: AppText.label.copyWith(color: c.text2)),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Caption — 12/500',
            style: AppText.caption.copyWith(color: c.text3),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '00:42 / 04:17 · 1.25×',
            style: AppText.monoTime.copyWith(color: c.text),
          ),
        ],
      ),
    );
  }
}
