import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/folder.dart';
import 'lesson_labels.dart';

/// Карточка папки для сетки на планшете. Отличается от урока брендовой
/// «крышкой» с иконкой-папкой — так папку видно среди уроков.
class FolderGridCard extends StatelessWidget {
  const FolderGridCard({super.key, required this.folder, required this.onTap});

  final Folder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticLabel: folder.title,
      child: ClipRRect(
        borderRadius: AppRadii.rXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 88,
              decoration: const BoxDecoration(gradient: AppBrand.signGradient),
              padding: const EdgeInsets.all(AppSpacing.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppIcon(
                    AppIcons.folder,
                    size: AppSizes.iconLg,
                    color: colors.primaryOn,
                  ),
                  if (folder.isPrivate)
                    AppIcon(
                      AppIcons.lock,
                      size: AppSizes.iconSm,
                      color: colors.primaryOn,
                      semanticLabel: 'Приватная',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    folder.title,
                    style: AppText.title.copyWith(color: colors.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    'Папка · ${lessonsLabel(folder.lessonCount)}',
                    style: AppText.caption.copyWith(color: colors.text2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
