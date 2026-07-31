import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Раздел витрины: заголовок, пояснение и карточка с содержимым.
class GallerySection extends StatelessWidget {
  const GallerySection({
    super.key,
    required this.title,
    required this.child,
    this.caption,
  });

  final String title;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h1.copyWith(color: c.text)),
          if (caption case final text?) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(text, style: AppText.caption.copyWith(color: c.text3)),
          ],
          const SizedBox(height: AppSpacing.s5),
          AppCard(child: child),
        ],
      ),
    );
  }
}
