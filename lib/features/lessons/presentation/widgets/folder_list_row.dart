import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/folder.dart';
import 'lesson_labels.dart';

/// Строка папки в общем списке. Отличается от урока квадратной иконкой-папкой
/// с брендовой заливкой и стрелкой справа — чтобы папку было видно с первого
/// взгляда. Тап проваливается в её уроки.
class FolderListRow extends StatefulWidget {
  const FolderListRow({super.key, required this.folder, required this.onTap});

  final Folder folder;
  final VoidCallback onTap;

  @override
  State<FolderListRow> createState() => _FolderListRowState();
}

class _FolderListRowState extends State<FolderListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final folder = widget.folder;

    return Semantics(
      button: true,
      label: folder.title,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) => setState(() => _hovered = value),
          borderRadius: AppRadii.rLg,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: AnimatedContainer(
            duration: context.motion(AppDurations.fast),
            curve: AppCurves.standard,
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: _hovered ? colors.surface2 : Colors.transparent,
              borderRadius: AppRadii.rLg,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppBrand.signGradient,
                    borderRadius: AppRadii.rLg,
                  ),
                  child: Center(
                    child: AppIcon(
                      AppIcons.folder,
                      size: AppSizes.iconLg,
                      color: colors.primaryOn,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              folder.title,
                              style: AppText.title.copyWith(color: colors.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (folder.isPrivate) ...[
                            const SizedBox(width: AppSpacing.s2),
                            AppIcon(
                              AppIcons.lock,
                              size: AppSizes.iconSm,
                              color: colors.text2,
                              semanticLabel: 'Приватная',
                            ),
                          ],
                        ],
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
                const SizedBox(width: AppSpacing.s2),
                AppIcon(
                  AppIcons.chevronRight,
                  size: AppSizes.iconMd,
                  color: colors.text3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
